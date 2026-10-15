import 'dart:async';
import 'dart:io';

import 'package:spy_dev_det/features/scan/data/mdns_device_discovery.dart';
import 'package:spy_dev_det/features/scan/data/native_multicast_lock.dart';
import 'package:spy_dev_det/features/scan/data/native_neighbor_repository.dart';
import 'package:spy_dev_det/features/scan/data/native_reachability_discovery.dart';
import 'package:spy_dev_det/features/scan/data/ssdp_device_discovery.dart';
import 'package:spy_dev_det/features/scan/data/tcp_device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/device_classifier.dart';
import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation_merger.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/mac_address.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_enricher.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class LocalNetworkDeviceScanner implements DeviceScanner {
  const LocalNetworkDeviceScanner({
    this.tcpScanner = const TcpDeviceScanner(),
    this.reachabilityDiscovery = const NativeReachabilityDiscovery(),
    this.mdnsDiscovery = const MdnsDeviceDiscovery(),
    this.ssdpDiscovery = const SsdpDeviceDiscovery(),
    this.neighborRepository = const NativeNeighborRepository(),
    this.multicastLock = const NativeMulticastLock(),
    this.classifier = const DeviceClassifier(),
    this.enricher = const NeighborEnricher(),
    this.merger = const DeviceObservationMerger(),
  });

  final DeviceScanner tcpScanner;
  final DeviceDiscovery reachabilityDiscovery;
  final DeviceDiscovery mdnsDiscovery;
  final DeviceDiscovery ssdpDiscovery;
  final NeighborRepository neighborRepository;
  final NativeMulticastLock multicastLock;
  final DeviceClassifier classifier;
  final NeighborEnricher enricher;
  final DeviceObservationMerger merger;

  @override
  Stream<ScanEvent> scan(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) {
    late final StreamController<ScanEvent> controller;
    controller = StreamController<ScanEvent>(
      onCancel: () {
        if (!controller.isClosed) {
          cancellationToken.cancel();
        }
      },
    );
    unawaited(
      _run(plan, cancellationToken, controller)
          .onError((Object error, StackTrace stackTrace) {
            if (!controller.isClosed) {
              controller.addError(error, stackTrace);
            }
          })
          .whenComplete(() {
            if (!controller.isClosed) {
              controller.close();
            }
          }),
    );
    return controller.stream;
  }

  Future<void> _run(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
    StreamController<ScanEvent> controller,
  ) async {
    final stopwatch = Stopwatch()..start();
    final observations = <String, DeviceObservation>{};
    final tcpAddresses = <String>{};
    var completedTargets = 0;
    controller.add(ScanStarted(totalTargets: plan.targets.length));
    _storeAndEmit(observations, _selfObservation(plan), plan, controller);
    final tcpStopwatch = Stopwatch()..start();
    controller.add(
      const ScanMethodStatusChanged(
        DiscoveryMethodResult(
          method: DiscoveryMethod.tcp,
          phase: DiscoveryMethodPhase.running,
        ),
      ),
    );

    await for (final event in tcpScanner.scan(plan, cancellationToken)) {
      switch (event) {
        case ScanStarted():
          break;
        case ScanProgress():
          completedTargets = event.completedTargets;
          controller.add(event);
        case ScanStageChanged():
          controller.add(event);
        case ScanMethodStatusChanged():
          controller.add(event);
        case DeviceObserved():
          tcpAddresses.add(event.device.ipAddress);
          _storeAndEmit(observations, event.device, plan, controller);
        case ScanCompleted():
          completedTargets = event.completedTargets;
          tcpStopwatch.stop();
          controller.add(
            ScanMethodStatusChanged(
              DiscoveryMethodResult(
                method: DiscoveryMethod.tcp,
                phase: DiscoveryMethodPhase.completed,
                deviceCount: tcpAddresses.length,
                elapsed: tcpStopwatch.elapsed,
              ),
            ),
          );
        case ScanCancelled():
          tcpStopwatch.stop();
          controller.add(
            ScanMethodStatusChanged(
              DiscoveryMethodResult(
                method: DiscoveryMethod.tcp,
                phase: DiscoveryMethodPhase.cancelled,
                deviceCount: tcpAddresses.length,
                elapsed: tcpStopwatch.elapsed,
              ),
            ),
          );
          controller.add(const ScanCancelled());
          return;
        case ScanFailed():
          tcpStopwatch.stop();
          controller.add(
            ScanMethodStatusChanged(
              DiscoveryMethodResult(
                method: DiscoveryMethod.tcp,
                phase: DiscoveryMethodPhase.failed,
                deviceCount: tcpAddresses.length,
                elapsed: tcpStopwatch.elapsed,
                userMessage: event.userMessage,
              ),
            ),
          );
          controller.add(event);
          return;
      }
    }

    if (cancellationToken.isCancelled) {
      controller.add(const ScanCancelled());
      return;
    }

    controller.add(
      const ScanStageChanged('Ağdaki cihazların erişilebilirliği doğrulanıyor'),
    );
    final reachableDevices = await _runDiscovery(
      method: DiscoveryMethod.reachability,
      discovery: reachabilityDiscovery,
      plan: plan,
      cancellationToken: cancellationToken,
      controller: controller,
    );
    for (final device in reachableDevices) {
      _storeAndEmit(observations, device, plan, controller);
    }

    if (cancellationToken.isCancelled) {
      controller.add(const ScanCancelled());
      return;
    }

    controller.add(
      const ScanStageChanged('mDNS ve SSDP servis duyuruları dinleniyor'),
    );
    var lockAcquired = false;
    try {
      await multicastLock.acquire();
      lockAcquired = true;
    } on Object {
      lockAcquired = false;
    }
    try {
      final discoveries = await Future.wait([
        _runDiscovery(
          method: DiscoveryMethod.mdns,
          discovery: mdnsDiscovery,
          plan: plan,
          cancellationToken: cancellationToken,
          controller: controller,
          warning: lockAcquired
              ? null
              : 'Çok noktaya yayın kilidi alınamadı; sonuçlar eksik olabilir.',
        ),
        _runDiscovery(
          method: DiscoveryMethod.ssdp,
          discovery: ssdpDiscovery,
          plan: plan,
          cancellationToken: cancellationToken,
          controller: controller,
          warning: lockAcquired
              ? null
              : 'Çok noktaya yayın kilidi alınamadı; sonuçlar eksik olabilir.',
        ),
      ]);
      for (final discovery in discoveries) {
        for (final device in discovery) {
          _storeAndEmit(observations, device, plan, controller);
        }
      }
    } finally {
      if (lockAcquired) {
        try {
          await multicastLock.release();
        } on Object {
          // The scan can still complete when the operating system has already
          // released the process-scoped multicast lock.
        }
      }
    }

    if (cancellationToken.isCancelled) {
      controller.add(const ScanCancelled());
      return;
    }

    controller.add(
      const ScanStageChanged('MAC ve üretici bilgileri zenginleştiriliyor'),
    );
    controller.add(
      const ScanMethodStatusChanged(
        DiscoveryMethodResult(
          method: DiscoveryMethod.neighbor,
          phase: DiscoveryMethodPhase.running,
        ),
      ),
    );
    final neighborStopwatch = Stopwatch()..start();
    final neighborSnapshot = await neighborRepository.getSnapshot();
    if (neighborSnapshot.available) {
      for (final entry in neighborSnapshot.entries) {
        if (entry.ipAddress == plan.network.localIpv4 ||
            (!plan.targets.contains(entry.ipAddress) &&
                entry.ipAddress != plan.network.gatewayIpv4) ||
            MacAddress.tryParse(entry.macAddress) == null) {
          continue;
        }
        _storeAndEmit(
          observations,
          _neighborObservation(entry, plan),
          plan,
          controller,
        );
      }
    }
    var enrichedDeviceCount = 0;
    for (final entry in observations.entries.toList()) {
      final enriched = classifier.classify(
        enricher.enrich(entry.value, neighborSnapshot),
        gatewayIpv4: plan.network.gatewayIpv4,
      );
      if (enriched.macStatus == MacStatus.available) {
        enrichedDeviceCount++;
      }
      observations[entry.key] = enriched;
      controller.add(DeviceObserved(enriched));
    }
    neighborStopwatch.stop();
    controller.add(
      ScanMethodStatusChanged(
        DiscoveryMethodResult(
          method: DiscoveryMethod.neighbor,
          phase: neighborSnapshot.available
              ? DiscoveryMethodPhase.completed
              : DiscoveryMethodPhase.unavailable,
          deviceCount: enrichedDeviceCount,
          elapsed: neighborStopwatch.elapsed,
          userMessage: neighborSnapshot.available
              ? null
              : 'İşletim sistemi MAC komşu tablosuna erişim sağlamadı.',
        ),
      ),
    );

    stopwatch.stop();
    controller.add(
      ScanCompleted(
        completedTargets: completedTargets,
        elapsed: stopwatch.elapsed,
      ),
    );
  }

  Future<List<DeviceObservation>> _runDiscovery({
    required DiscoveryMethod method,
    required DeviceDiscovery discovery,
    required ScanPlan plan,
    required ScanCancellationToken cancellationToken,
    required StreamController<ScanEvent> controller,
    String? warning,
  }) async {
    final stopwatch = Stopwatch()..start();
    controller.add(
      ScanMethodStatusChanged(
        DiscoveryMethodResult(
          method: method,
          phase: DiscoveryMethodPhase.running,
          userMessage: warning,
        ),
      ),
    );
    try {
      final devices = await discovery.discover(plan, cancellationToken);
      stopwatch.stop();
      controller.add(
        ScanMethodStatusChanged(
          DiscoveryMethodResult(
            method: method,
            phase: cancellationToken.isCancelled
                ? DiscoveryMethodPhase.cancelled
                : DiscoveryMethodPhase.completed,
            deviceCount: devices.length,
            elapsed: stopwatch.elapsed,
            userMessage: warning,
          ),
        ),
      );
      return devices;
    } on ReachabilityUnavailableException {
      stopwatch.stop();
      controller.add(
        ScanMethodStatusChanged(
          DiscoveryMethodResult(
            method: method,
            phase: DiscoveryMethodPhase.unavailable,
            elapsed: stopwatch.elapsed,
            userMessage: _discoveryErrorMessage(method, null),
          ),
        ),
      );
      return const [];
    } on SocketException catch (error) {
      stopwatch.stop();
      controller.add(
        ScanMethodStatusChanged(
          DiscoveryMethodResult(
            method: method,
            phase: DiscoveryMethodPhase.unavailable,
            elapsed: stopwatch.elapsed,
            userMessage: _discoveryErrorMessage(method, error.message),
          ),
        ),
      );
      return const [];
    } on Object {
      stopwatch.stop();
      controller.add(
        ScanMethodStatusChanged(
          DiscoveryMethodResult(
            method: method,
            phase: DiscoveryMethodPhase.failed,
            elapsed: stopwatch.elapsed,
            userMessage: _discoveryErrorMessage(method, null),
          ),
        ),
      );
      return const [];
    }
  }

  String _discoveryErrorMessage(DiscoveryMethod method, String? detail) {
    final prefix = switch (method) {
      DiscoveryMethod.reachability => 'Cihaz erişilebilirlik',
      DiscoveryMethod.mdns => 'mDNS',
      DiscoveryMethod.ssdp => 'SSDP',
      DiscoveryMethod.tcp => 'TCP',
      DiscoveryMethod.neighbor => 'Komşu tablosu',
    };
    return '$prefix keşfi bu ağda kullanılamadı.';
  }

  DeviceObservation _selfObservation(ScanPlan plan) {
    return DeviceObservation(
      id: 'device-${plan.network.localIpv4}',
      ipAddress: plan.network.localIpv4,
      displayName: 'Bu cihaz',
      macStatus: MacStatus.notObserved,
      services: const [],
      discoveryMethod: 'Ağ bilgisi',
      evidence: const [
        DeviceEvidence(
          source: DeviceEvidenceSource.network,
          description: 'Taramanın çalıştığı cihaz',
        ),
      ],
    );
  }

  DeviceObservation _neighborObservation(NeighborEntry entry, ScanPlan plan) {
    return DeviceObservation(
      id: 'device-${entry.ipAddress}',
      ipAddress: entry.ipAddress,
      displayName: entry.ipAddress == plan.network.gatewayIpv4
          ? 'Yönlendirici adayı'
          : 'Ağ komşusu',
      macStatus: MacStatus.notObserved,
      services: const [],
      discoveryMethod: 'Komşu tablosu',
      evidence: const [
        DeviceEvidence(
          source: DeviceEvidenceSource.neighbor,
          description: 'Cihaz yerel ağ komşu tablosunda görüldü',
        ),
      ],
    );
  }

  void _storeAndEmit(
    Map<String, DeviceObservation> observations,
    DeviceObservation incoming,
    ScanPlan plan,
    StreamController<ScanEvent> controller,
  ) {
    final current = observations[incoming.ipAddress];
    final merged = current == null ? incoming : merger.merge(current, incoming);
    final classified = classifier.classify(
      merged,
      gatewayIpv4: plan.network.gatewayIpv4,
    );
    observations[incoming.ipAddress] = classified;
    controller.add(DeviceObserved(classified));
  }
}
