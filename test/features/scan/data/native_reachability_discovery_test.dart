import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/data/native_reachability_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('yusufs.turan.spydevdet/network_info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'yerel kanal yanıtını hedeflerle sınırlar ve yinelenenleri ayıklar',
    () async {
      final plan = _plan();
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'discoverReachableHosts');
        final arguments = call.arguments as Map<Object?, Object?>;
        expect(arguments['sourceAddress'], '192.168.1.20');
        expect(arguments['targets'], plan.targets);
        return <String>[plan.targets.first, plan.targets.first, '192.168.2.40'];
      });

      final result = await const NativeReachabilityDiscovery(
        platformSupportedOverride: true,
      ).discover(plan, ScanCancellationToken());

      expect(result.devices, hasLength(1));
      expect(result.devices.single.ipAddress, plan.targets.first);
      expect(result.metrics.receivedResponses, 3);
      expect(result.metrics.acceptedResponses, 1);
      expect(result.metrics.ignoredResponses, 2);
    },
  );

  test('iptal edilen istek yerel iptal çağrısını gönderir', () async {
    final plan = _plan();
    final token = ScanCancellationToken();
    final discoveryStarted = Completer<void>();
    final nativeRequestFinished = Completer<void>();
    final cancellationReceived = Completer<void>();
    String? requestId;

    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = call.arguments as Map<Object?, Object?>;
      if (call.method == 'discoverReachableHosts') {
        requestId = arguments['requestId'] as String;
        discoveryStarted.complete();
        await nativeRequestFinished.future;
        return <String>[];
      }
      if (call.method == 'cancelReachability') {
        expect(arguments['requestId'], requestId);
        cancellationReceived.complete();
        nativeRequestFinished.complete();
        return null;
      }
      fail('Beklenmeyen platform çağrısı: ${call.method}');
    });

    final resultFuture = const NativeReachabilityDiscovery(
      platformSupportedOverride: true,
    ).discover(plan, token);
    await discoveryStarted.future;
    token.cancel();

    await cancellationReceived.future;
    final result = await resultFuture;
    expect(result.devices, isEmpty);
  });

  test(
    'platform hatasını kullanılmayan erişilebilirlik olarak bildirir',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'REACHABILITY_FAILED');
      });

      await expectLater(
        const NativeReachabilityDiscovery(platformSupportedOverride: true)
            .discover(_plan(), ScanCancellationToken()),
        throwsA(isA<ReachabilityUnavailableException>()),
      );
    },
  );
}

ScanPlan _plan() => ScanPlan.fromNetwork(
  const NetworkSnapshot(
    localIpv4: '192.168.1.20',
    prefixLength: 29,
    interfaceName: 'test',
    gatewayIpv4: '192.168.1.17',
    isWifi: true,
    isVpn: false,
  ),
);
