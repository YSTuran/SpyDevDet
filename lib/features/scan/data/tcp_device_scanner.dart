import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

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
  static const _quickPortNumbers = {80, 443, 554, 8000, 8080};
  static const _androidProbeLimit = 20;

  final int maxConcurrentProbes;
  final Duration probeTimeout;

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
    final ports = plan.mode == ScanMode.quick
        ? _ports
              .where((port) => _quickPortNumbers.contains(port.number))
              .toList(growable: false)
        : _ports;

    final openPortsByHost = <String, Set<int>>{};
    final rejectedPortByHost = <String, int>{};
    final responsiveHosts = <String>{};
    final remainingProbesByHost = <String, int>{
      for (final target in plan.targets) target: ports.length,
    };
    final totalJobs = plan.targets.length * ports.length;
    var nextJob = 0;
    var completedTargets = 0;
    var sentRequests = 0;
    var receivedResponses = 0;
    var timeoutCount = 0;

    Future<void> worker() async {
      while (!cancellationToken.isCancelled) {
        final jobIndex = nextJob++;
        if (jobIndex >= totalJobs) {
          return;
        }

        final hostIndex = jobIndex ~/ ports.length;
        final portIndex = jobIndex % ports.length;
        final host = plan.targets[hostIndex];
        final probePort = ports[portIndex];
        sentRequests++;
        final probeResult = await _probe(
          host: host,
          port: probePort.number,
          sourceAddress: plan.network.localIpv4,
          cancellationToken: cancellationToken,
        );

        if (cancellationToken.isCancelled) {
          return;
        }

        if (probeResult == _ProbeResult.timeout) {
          timeoutCount++;
        }
        if (probeResult == _ProbeResult.open ||
            probeResult == _ProbeResult.rejected) {
          receivedResponses++;
          final firstResponse = responsiveHosts.add(host);
          final openPorts = openPortsByHost.putIfAbsent(host, () => <int>{});
          if (probeResult == _ProbeResult.open) {
            openPorts.add(probePort.number);
          } else {
            rejectedPortByHost.putIfAbsent(host, () => probePort.number);
          }
          if (firstResponse || probeResult == _ProbeResult.open) {
            controller.add(
              DeviceObserved(
                _observationFor(
                  host: host,
                  gateway: plan.network.gatewayIpv4,
                  openPorts: openPorts,
                  rejectedPort: rejectedPortByHost[host],
                ),
              ),
            );
          }
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

    final platformConcurrency = Platform.isAndroid
        ? math.min(maxConcurrentProbes, _androidProbeLimit)
        : maxConcurrentProbes;
    final workerCount = math.min(platformConcurrency, totalJobs);
    await Future.wait(List.generate(workerCount, (_) => worker()));
    stopwatch.stop();

    if (cancellationToken.isCancelled) {
      controller.add(
        ScanCancelled(
          metrics: DiscoveryMetrics(
            attemptedTargets: completedTargets,
            sentRequests: sentRequests,
            receivedResponses: receivedResponses,
            acceptedResponses: responsiveHosts.length,
            timeoutCount: timeoutCount,
            detail:
                'Gerçek TCP bağlantı denemeleri; en fazla $workerCount eşzamanlı; '
                'tarama iptal edildi',
          ),
        ),
      );
      return;
    }
    controller.add(
      ScanCompleted(
        completedTargets: completedTargets,
        elapsed: stopwatch.elapsed,
        metrics: DiscoveryMetrics(
          attemptedTargets: completedTargets,
          sentRequests: sentRequests,
          receivedResponses: receivedResponses,
          acceptedResponses: responsiveHosts.length,
          timeoutCount: timeoutCount,
          detail:
              '${ports.length} sınırlı TCP portunda gerçek bağlantı denemeleri; '
              'en fazla $workerCount eşzamanlı',
        ),
      ),
    );
  }

  Future<_ProbeResult> _probe({
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
        return _ProbeResult.noResponse;
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
        return _ProbeResult.noResponse;
      }

      final socket = await connectionTask.socket.timeout(
        probeTimeout,
        onTimeout: () {
          connectionTask?.cancel();
          throw TimeoutException('TCP bağlantı zaman aşımına uğradı.');
        },
      );
      socket.destroy();
      return _ProbeResult.open;
    } on SocketException catch (error) {
      return _isActiveRefusal(error)
          ? _ProbeResult.rejected
          : _ProbeResult.noResponse;
    } on TimeoutException {
      return _ProbeResult.timeout;
    } finally {
      removeCancelListener();
    }
  }

  DeviceObservation _observationFor({
    required String host,
    required String? gateway,
    required Set<int> openPorts,
    required int? rejectedPort,
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
        if (rejectedPort != null)
          DeviceEvidence(
            source: DeviceEvidenceSource.tcp,
            description:
                'TCP $rejectedPort portu bağlantıyı reddetti; cihaz yanıt verdi',
            port: rejectedPort,
          ),
      ],
    );
  }

  bool _isActiveRefusal(SocketException error) {
    const activeResponseCodes = {111, 104, 10054, 10061};
    final code = error.osError?.errorCode;
    if (code != null && activeResponseCodes.contains(code)) {
      return true;
    }
    final message = '${error.message} ${error.osError?.message ?? ''}'
        .toLowerCase();
    return message.contains('connection refused') ||
        message.contains('connection reset');
  }
}

enum _ProbeResult { open, rejected, timeout, noResponse }

class _ProbePort {
  const _ProbePort(this.number, this.service);

  final int number;
  final String service;
}
