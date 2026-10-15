import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/network/data/native_network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/ipv4_address.dart';
import 'package:spy_dev_det/features/network/domain/network_info_repository.dart';
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

  @override
  ScanState build() {
    ref.onDispose(() {
      _runId++;
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
        _cancellationToken = null;
      }
    }
  }

  void cancelScan() {
    if (!state.isBusy) {
      return;
    }

    _runId++;
    _cancellationToken?.cancel();
    _cancellationToken = null;
    state = state.copyWith(
      phase: ScanPhase.cancelled,
      statusMessage: 'Tarama kullanıcı tarafından iptal edildi',
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
        final progress = event.totalTargets == 0
            ? 0.0
            : event.completedTargets / event.totalTargets;
        state = state.copyWith(
          progress: progress.clamp(0, 1),
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
          state = state.copyWith(report: report.withMethod(event.result));
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
          phase: ScanPhase.completed,
          progress: 1,
          scannedTargets: event.completedTargets,
          elapsed: event.elapsed,
          report: state.report?.complete(DateTime.now()),
          statusMessage: state.devices.isEmpty
              ? 'Kullanılan keşif yöntemlerinde cihaz gözlemlenmedi'
              : 'Tarama tamamlandı • ${state.devices.length} cihaz gözlemlendi',
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

  Future<void> _persistCompletedScan({
    required ScanPlan plan,
    required ScanCompleted event,
    required int runId,
  }) async {
    final report = state.report;
    if (report == null) {
      return;
    }
    try {
      final repository = ref.read(scanHistoryRepositoryProvider);
      final devices = await repository.recordCompletedScan(
        CompletedScanRecord(
          networkKey: const DeviceIdentityResolver().networkKey(plan),
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
          statusMessage: 'Tarama tamamlandı; geçmiş kaydedilemedi',
        );
      }
    }
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
