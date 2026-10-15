import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

class TcpDeviceScanner implements DeviceScanner {
  const TcpDeviceScanner({
    this.maxConcurrentProbes = 32,
    this.probeTimeout = const Duration(milliseconds: 450),
  });

  static const _ports = [
    _ProbePort(22, 'SSH'),
    _ProbePort(53, 'DNS'),
    _ProbePort(80, 'HTTP'),
    _ProbePort(443, 'HTTPS'),
    _ProbePort(554, 'RTSP'),
    _ProbePort(8000, 'Web/cihaz servisi'),
    _ProbePort(8080, 'Alternatif HTTP'),
    _ProbePort(9100, 'Yazıcı servisi'),
  ];

  final int maxConcurrentProbes;
  final Duration probeTimeout;

  @override
  Stream<ScanEvent> scan(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) {
    late final StreamController<ScanEvent> controller;
    controller = StreamController<ScanEvent>(
      onCancel: cancellationToken.cancel,
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
    if (maxConcurrentProbes < 1 || maxConcurrentProbes > 128) {
      throw RangeError.range(
        maxConcurrentProbes,
        1,
        128,
        'maxConcurrentProbes',
      );
    }

    final stopwatch = Stopwatch()..start();
    controller.add(ScanStarted(totalTargets: plan.targets.length));

    final openPortsByHost = <String, Set<int>>{};
    final remainingProbesByHost = <String, int>{
      for (final target in plan.targets) target: _ports.length,
    };
    final totalJobs = plan.targets.length * _ports.length;
    var nextJob = 0;
    var completedTargets = 0;

    Future<void> worker() async {
      while (!cancellationToken.isCancelled) {
        final jobIndex = nextJob++;
        if (jobIndex >= totalJobs) {
          return;
        }

        final hostIndex = jobIndex ~/ _ports.length;
        final portIndex = jobIndex % _ports.length;
        final host = plan.targets[hostIndex];
        final probePort = _ports[portIndex];
        final isOpen = await _probe(
          host: host,
          port: probePort.number,
          sourceAddress: plan.network.localIpv4,
          cancellationToken: cancellationToken,
        );

        if (cancellationToken.isCancelled) {
          return;
        }

        if (isOpen) {
          final openPorts = openPortsByHost.putIfAbsent(host, () => <int>{});
          openPorts.add(probePort.number);
          controller.add(
            DeviceObserved(
              _observationFor(
                host: host,
                gateway: plan.network.gatewayIpv4,
                openPorts: openPorts,
              ),
            ),
          );
        }

        final remaining = remainingProbesByHost[host]! - 1;
        remainingProbesByHost[host] = remaining;
        if (remaining == 0) {
          completedTargets++;
          controller.add(
            ScanProgress(
              completedTargets: completedTargets,
              totalTargets: plan.targets.length,
            ),
          );
        }
      }
    }

    final workerCount = math.min(maxConcurrentProbes, totalJobs);
    await Future.wait(List.generate(workerCount, (_) => worker()));
    stopwatch.stop();

    if (cancellationToken.isCancelled) {
      controller.add(const ScanCancelled());
      return;
    }
    controller.add(
      ScanCompleted(
        completedTargets: completedTargets,
        elapsed: stopwatch.elapsed,
      ),
    );
  }

  Future<bool> _probe({
    required String host,
    required int port,
    required String sourceAddress,
    required ScanCancellationToken cancellationToken,
  }) async {
    ConnectionTask<Socket>? connectionTask;
    final removeCancelListener = cancellationToken.addCancelListener(() {
      connectionTask?.cancel();
    });

    try {
      if (cancellationToken.isCancelled) {
        return false;
      }
      connectionTask = await Socket.startConnect(
        InternetAddress(host, type: InternetAddressType.IPv4),
        port,
        sourceAddress: InternetAddress(
          sourceAddress,
          type: InternetAddressType.IPv4,
        ),
      );
      if (cancellationToken.isCancelled) {
        connectionTask.cancel();
        return false;
      }

      final socket = await connectionTask.socket.timeout(
        probeTimeout,
        onTimeout: () {
          connectionTask?.cancel();
          throw TimeoutException('TCP bağlantı zaman aşımına uğradı.');
        },
      );
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } finally {
      removeCancelListener();
    }
  }

  DeviceObservation _observationFor({
    required String host,
    required String? gateway,
    required Set<int> openPorts,
  }) {
    final sortedPorts = openPorts.toList()..sort();
    final services = sortedPorts
        .map((port) {
          final definition = _ports.firstWhere((item) => item.number == port);
          return '${definition.service} (${definition.number})';
        })
        .toList(growable: false);

    return DeviceObservation(
      id: 'device-$host',
      ipAddress: host,
      displayName: host == gateway ? 'Yönlendirici adayı' : 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: services,
      discoveryMethod: 'TCP bağlantı denemesi',
      evidence: [
        if (host == gateway)
          const DeviceEvidence(
            source: DeviceEvidenceSource.network,
            description: 'İşletim sistemi bu adresi ağ geçidi olarak bildirdi',
          ),
        ...sortedPorts.map(
          (port) => DeviceEvidence(
            source: DeviceEvidenceSource.tcp,
            description: 'TCP $port portu bağlantı kabul etti',
            port: port,
          ),
        ),
      ],
    );
  }
}

class _ProbePort {
  const _ProbePort(this.number, this.service);

  final int number;
  final String service;
}
