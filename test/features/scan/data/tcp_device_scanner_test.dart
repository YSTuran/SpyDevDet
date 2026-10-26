import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/data/tcp_device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

void main() {
  final plan = ScanPlan.fromNetwork(
    const NetworkSnapshot(
      localIpv4: '192.168.254.1',
      prefixLength: 30,
      interfaceName: 'test',
      gatewayIpv4: '192.168.254.2',
      isWifi: true,
      isVpn: false,
    ),
  );

  test('normal tamamlanma ortak iptal anahtarını iptal etmez', () async {
    final token = ScanCancellationToken();
    const scanner = TcpDeviceScanner(
      maxConcurrentProbes: 8,
      probeTimeout: Duration(milliseconds: 1),
    );

    final events = await scanner.scan(plan, token).toList();
    final completed = events.whereType<ScanCompleted>().single;

    expect(completed.metrics.attemptedTargets, 1);
    expect(completed.metrics.sentRequests, 10);
    expect(
      completed.metrics.receivedResponses + completed.metrics.timeoutCount,
      lessThanOrEqualTo(10),
    );
    expect(token.isCancelled, isFalse);
  });

  test('dinleyici erken ayrılırsa tarama iptal edilir', () async {
    final token = ScanCancellationToken();
    const scanner = TcpDeviceScanner(
      maxConcurrentProbes: 1,
      probeTimeout: Duration(seconds: 1),
    );
    final started = Completer<void>();
    late StreamSubscription<ScanEvent> subscription;
    subscription = scanner.scan(plan, token).listen((event) {
      if (event is ScanStarted && !started.isCompleted) {
        started.complete();
      }
    });

    await started.future;
    await subscription.cancel();

    expect(token.isCancelled, isTrue);
  });
}
