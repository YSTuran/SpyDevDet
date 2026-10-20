import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/network/data/native_network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/ipv4_address.dart';
import 'package:spy_dev_det/features/network/domain/network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/data/local_network_device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_identity_resolver.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

final networkInfoRepositoryProvider = Provider<NetworkInfoRepository>(
  (ref) => const NativeNetworkInfoRepository(),
);

final deviceScannerProvider = Provider<DeviceScanner>(
  (ref) => const LocalNetworkDeviceScanner(),
);

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

class ScanController extends Notifier<ScanState> {
  int _runId = 0;
  ScanCancellationToken? _cancellationToken;
  Timer? _networkMonitor;
  int _networkMonitorGeneration = 0;
  int? _networkCheckInProgressGeneration;
  int _networkCheckFailures = 0;

  @override
  ScanState build() {
    ref.onDispose(() {
      _runId++;
      _stopNetworkMonitor();
      _cancellationToken?.cancel();
    });
    return const ScanState.idle();
  }

  Future<void> startScan() async {
    if (state.isBusy) {
      return;
    }

    final runId = ++_runId;
    _cancellationToken?.cancel();
    _cancellationToken = null;
    _stopNetworkMonitor();
    state = const ScanState(
      phase: ScanPhase.preparing,
      progress: 0,
      devices: [],
      statusMessage: 'Etkin yerel ağ bağlantısı kontrol ediliyor',
      scannedTargets: 0,
      totalTargets: 0,
      rangeTruncated: false,
    );

    try {
      final repository = ref.read(networkInfoRepositoryProvider);
      final network = await repository.getCurrentNetwork();
      if (runId != _runId) {
        return;
      }

      final plan = ScanPlan.fromNetwork(network);
      final cancellationToken = ScanCancellationToken();
      _cancellationToken = cancellationToken;
      _startNetworkMonitor(runId, network);
      final startedAt = DateTime.now();
      state = ScanState(
        phase: ScanPhase.scanning,
        progress: 0,
        devices: const [],
        statusMessage: '${plan.targets.length} yerel adres kontrol edilecek',
        scannedTargets: 0,
        totalTargets: plan.targets.length,
        rangeTruncated: plan.isTruncated,
        network: network,
        scanRange: plan.rangeLabel,
        report: ScanReport.started(startedAt),
      );

      final scanner = ref.read(deviceScannerProvider);
      await for (final event in scanner.scan(plan, cancellationToken)) {
        if (runId != _runId) {
          return;
        }
        _handleEvent(event);
        if (event is ScanCompleted) {
          _stopNetworkMonitor();
          if (!await _networkStillMatches(network)) {
            if (runId == _runId) {
              _invalidateScanForNetworkChange();
            }
            return;
          }
          if (runId != _runId || state.phase != ScanPhase.saving) {
            return;
          }
          await _persistCompletedScan(plan: plan, event: event, runId: runId);
        }
      }
    } on NetworkInfoException catch (error) {
      if (runId == _runId) {
        _fail(error.userMessage);
      }
    } on ScanPlanningException catch (error) {
      if (runId == _runId) {
        _fail(error.userMessage);
      }
    } on Object {
      if (runId == _runId) {
        _fail('Tarama beklenmeyen bir nedenle tamamlanamadı.');
      }
    } finally {
      if (runId == _runId) {
        _stopNetworkMonitor();
        _cancellationToken = null;
      }
    }
  }

  void cancelScan({
    String message = 'Tarama kullanıcı tarafından iptal edildi',
  }) {
    if (!state.canCancel) {
      return;
    }

    _runId++;
    _stopNetworkMonitor();
    _cancellationToken?.cancel();
    _cancellationToken = null;
    state = state.copyWith(
      phase: ScanPhase.cancelled,
      statusMessage: message,
      report: state.report?.cancelRunning(),
    );
  }

  void _startNetworkMonitor(int runId, NetworkSnapshot expected) {
    _stopNetworkMonitor();
    final generation = ++_networkMonitorGeneration;
    _networkCheckFailures = 0;
    _networkMonitor = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_verifyNetworkDuringScan(runId, generation, expected));
    });
  }

  void _stopNetworkMonitor() {
    _networkMonitor?.cancel();
    _networkMonitor = null;
    _networkMonitorGeneration++;
    _networkCheckFailures = 0;
  }

  Future<void> _verifyNetworkDuringScan(
    int runId,
    int generation,
    NetworkSnapshot expected,
  ) async {
    if (_networkCheckInProgressGeneration == generation ||
        generation != _networkMonitorGeneration ||
        runId != _runId ||
        state.phase != ScanPhase.scanning) {
      return;
    }
    _networkCheckInProgressGeneration = generation;
    try {
      final current = await ref
          .read(networkInfoRepositoryProvider)
          .getCurrentNetwork();
      if (runId != _runId ||
          generation != _networkMonitorGeneration ||
          state.phase != ScanPhase.scanning) {
        return;
      }
      if (_sameNetwork(expected, current)) {
        _networkCheckFailures = 0;
      } else {
        _invalidateScanForNetworkChange();
      }
    } on Object {
      if (runId == _runId &&
          generation == _networkMonitorGeneration &&
          state.phase == ScanPhase.scanning) {
        _networkCheckFailures++;
        if (_networkCheckFailures >= 2) {
          _invalidateScanForNetworkChange();
        }
      }
    } finally {
      if (_networkCheckInProgressGeneration == generation) {
        _networkCheckInProgressGeneration = null;
      }
    }
  }

  Future<bool> _networkStillMatches(NetworkSnapshot expected) async {
    try {
      final current = await ref
          .read(networkInfoRepositoryProvider)
          .getCurrentNetwork();
      return _sameNetwork(expected, current);
    } on Object {
      return false;
    }
  }

  bool _sameNetwork(NetworkSnapshot first, NetworkSnapshot second) =>
      first.localIpv4 == second.localIpv4 &&
      first.prefixLength == second.prefixLength &&
      first.interfaceName == second.interfaceName &&
      first.gatewayIpv4 == second.gatewayIpv4 &&
      first.isWifi == second.isWifi &&
      first.isEthernet == second.isEthernet &&
      first.isVpn == second.isVpn;

  void _invalidateScanForNetworkChange() {
    _runId++;
    _stopNetworkMonitor();
    _cancellationToken?.cancel();
    _cancellationToken = null;
    state = state.copyWith(
      phase: ScanPhase.failed,
      statusMessage:
          'Ağ bağlantısı tarama sırasında değişti. Sonuçlar kaydedilmedi.',
      report: state.report?.cancelRunning(),
    );
  }

  void _handleEvent(ScanEvent event) {
    switch (event) {
      case ScanStarted():
        state = state.copyWith(
          totalTargets: event.totalTargets,
          statusMessage: '${event.totalTargets} yerel adres taranıyor',
        );
      case ScanProgress():
        state = state.copyWith(
          progress: _scanProgress(
            report: state.report,
            scannedTargets: event.completedTargets,
            totalTargets: event.totalTargets,
          ),
          scannedTargets: event.completedTargets,
          totalTargets: event.totalTargets,
          statusMessage:
              '${state.devices.length} cihaz gözlemlendi • '
              '${event.completedTargets}/${event.totalTargets} adres',
        );
      case ScanStageChanged():
        state = state.copyWith(statusMessage: event.userMessage);
      case ScanMethodStatusChanged():
        final report = state.report;
        if (report != null) {
          final updatedReport = report.withMethod(event.result);
          state = state.copyWith(
            report: updatedReport,
            progress: _scanProgress(
              report: updatedReport,
              scannedTargets: state.scannedTargets,
              totalTargets: state.totalTargets,
            ),
          );
        }
      case DeviceObserved():
        final devices = _upsertDevice(state.devices, event.device);
        state = state.copyWith(
          devices: devices,
          statusMessage:
              '${devices.length} cihaz gözlemlendi • '
              '${state.scannedTargets}/${state.totalTargets} adres',
        );
      case ScanCompleted():
        state = state.copyWith(
          phase: ScanPhase.saving,
          progress: 1,
          scannedTargets: event.completedTargets,
          elapsed: event.elapsed,
          report: state.report?.complete(DateTime.now()),
          statusMessage: 'Tarama tamamlandı • geçmişe kaydediliyor',
        );
      case ScanCancelled():
        state = state.copyWith(
          phase: ScanPhase.cancelled,
          statusMessage: 'Tarama iptal edildi',
          report: state.report?.cancelRunning(),
        );
      case ScanFailed():
        _fail(event.userMessage);
    }
  }

  void _fail(String message) {
    state = state.copyWith(phase: ScanPhase.failed, statusMessage: message);
  }

  double _scanProgress({
    required ScanReport? report,
    required int scannedTargets,
    required int totalTargets,
  }) {
    if (report == null) {
      return 0;
    }
    const weights = <DiscoveryMethod, double>{
      DiscoveryMethod.tcp: 0.60,
      DiscoveryMethod.reachability: 0.15,
      DiscoveryMethod.mdns: 0.075,
      DiscoveryMethod.ssdp: 0.075,
      DiscoveryMethod.onvif: 0.05,
      DiscoveryMethod.neighbor: 0.05,
    };
    var value = 0.0;
    for (final entry in weights.entries) {
      final result = report.methods[entry.key];
      if (entry.key == DiscoveryMethod.tcp &&
          result?.phase == DiscoveryMethodPhase.running) {
        final fraction = totalTargets == 0
            ? 0.0
            : scannedTargets / totalTargets;
        value += entry.value * fraction.clamp(0, 1);
      } else if (result != null && _isTerminal(result.phase)) {
        value += entry.value;
      }
    }
    return value.clamp(0, 0.99);
  }

  bool _isTerminal(DiscoveryMethodPhase phase) => switch (phase) {
    DiscoveryMethodPhase.completed ||
    DiscoveryMethodPhase.unavailable ||
    DiscoveryMethodPhase.failed ||
    DiscoveryMethodPhase.cancelled => true,
    DiscoveryMethodPhase.waiting || DiscoveryMethodPhase.running => false,
  };

  Future<void> _persistCompletedScan({
    required ScanPlan plan,
    required ScanCompleted event,
    required int runId,
  }) async {
    final report = state.report;
    if (report == null) {
      if (runId == _runId) {
        state = state.copyWith(
          phase: ScanPhase.completed,
          statusMessage: 'Tarama tamamlandı; rapor kaydedilemedi',
        );
      }
      return;
    }
    try {
      final repository = ref.read(scanHistoryRepositoryProvider);
      final gatewayMacAddress = _gatewayMacAddress(plan);
      const identityResolver = DeviceIdentityResolver();
      final devices = await repository.recordCompletedScan(
        CompletedScanRecord(
          networkKey: identityResolver.networkKey(plan),
          networkIdentityKeys: identityResolver.networkIdentityKeys(
            plan,
            gatewayMacAddress: gatewayMacAddress,
          ),
          report: report,
          elapsed: event.elapsed,
          devices: state.devices,
        ),
      );
      if (runId != _runId) {
        return;
      }
      final newDeviceCount = devices
          .where((device) => device.familiarity == DeviceFamiliarity.newDevice)
          .length;
      state = state.copyWith(
        phase: ScanPhase.completed,
        devices: List.unmodifiable(devices),
        statusMessage: devices.isEmpty
            ? 'Tarama tamamlandı • geçmişe kaydedildi'
            : 'Tarama tamamlandı • ${devices.length} cihaz • '
                  '$newDeviceCount yeni',
      );
      ref.invalidate(scanHistoryProvider);
    } on Object {
      if (runId == _runId) {
        state = state.copyWith(
          phase: ScanPhase.completed,
          statusMessage: 'Tarama tamamlandı; geçmiş kaydedilemedi',
        );
      }
    }
  }

  String? _gatewayMacAddress(ScanPlan plan) {
    for (final device in state.devices) {
      if (device.ipAddress == plan.network.gatewayIpv4 &&
          device.macStatus == MacStatus.available) {
        return device.macAddress;
      }
    }
    return null;
  }

  Future<void> updateDeviceProfile({
    required DeviceObservation device,
    required bool isKnown,
    required String? customName,
    required String? note,
  }) async {
    final stableKey = device.stableKey;
    if (stableKey == null) {
      return;
    }
    final repository = ref.read(scanHistoryRepositoryProvider);
    await repository.updateDeviceProfile(
      stableKey: stableKey,
      isKnown: isKnown,
      customName: customName,
      note: note,
    );
    final updatedDevices = state.devices
        .map(
          (item) => item.stableKey == stableKey
              ? item.copyWith(
                  customName: customName,
                  clearCustomName: customName?.trim().isEmpty != false,
                  note: note,
                  clearNote: note?.trim().isEmpty != false,
                  familiarity: isKnown
                      ? DeviceFamiliarity.known
                      : DeviceFamiliarity.seenBefore,
                )
              : item,
        )
        .toList(growable: false);
    state = state.copyWith(devices: List.unmodifiable(updatedDevices));
    ref.invalidate(scanHistoryProvider);
  }

  List<DeviceObservation> _upsertDevice(
    List<DeviceObservation> current,
    DeviceObservation incoming,
  ) {
    final devices = [...current];
    final index = devices.indexWhere(
      (device) => device.ipAddress == incoming.ipAddress,
    );
    if (index == -1) {
      devices.add(incoming);
    } else {
      devices[index] = incoming;
    }
    devices.sort(
      (first, second) => Ipv4Address.compare(first.ipAddress, second.ipAddress),
    );
    return List.unmodifiable(devices);
  }
}
