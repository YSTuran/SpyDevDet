import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';
import 'package:spy_dev_det/features/onboarding/application/onboarding_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const networkInfoChannel = MethodChannel(
    'yusufs.turan.spydevdet/network_info',
  );

  testWidgets('ana bölümler gerçek uygulama kabuğunda açılır', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialOnboardingCompletedProvider.overrideWithValue(true)],
        child: const SpyDevDetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yerel ağı tara'), findsOneWidget);

    await tester.tap(find.text('Cihazlar'));
    await tester.pumpAndSettle();
    expect(find.text('Cihazlarda ara'), findsOneWidget);
    expect(find.textContaining('Kayıtlı cihaz profilleri'), findsOneWidget);

    await tester.tap(find.text('Ağlar'));
    await tester.pumpAndSettle();
    expect(find.text('Ağ profilleri'), findsOneWidget);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Görünüm modu'), findsOneWidget);
    expect(find.text('Renk teması'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('yerel ağ platform kanalı gerçek uygulamada yanıt verir', (
    tester,
  ) async {
    try {
      final snapshot = await networkInfoChannel
          .invokeMapMethod<String, Object?>('getNetworkSnapshot');
      expect(snapshot, isNotNull);
      expect(snapshot, contains('localIpv4'));
      expect(snapshot, contains('prefixLength'));
      expect(snapshot, contains('isVpn'));
    } on PlatformException catch (error) {
      // Android emülatörü her zaman Wi-Fi taşıması sunmaz. Bu hata kodları da
      // yerel kanalın çalıştığını ve güvenli biçimde taramayı reddettiğini
      // doğrular.
      expect(const {
        'NO_ACTIVE_NETWORK',
        'NETWORK_UNAVAILABLE',
        'VPN_ACTIVE',
        'WIFI_REQUIRED',
        'LINK_UNAVAILABLE',
        'NO_IPV4_ADDRESS',
        'NO_PRIVATE_IPV4',
        'WINDOWS_NETWORK_QUERY_FAILED',
      }, contains(error.code));
    }

    final neighbors = await networkInfoChannel.invokeMapMethod<String, Object?>(
      'getNeighborSnapshot',
    );
    expect(neighbors, isNotNull);
    expect(neighbors, contains('available'));
    expect(neighbors, contains('entries'));

    await expectLater(
      networkInfoChannel.invokeMethod<Object?>('discoverReachableHosts', {
        'requestId': '',
        'targets': <String>[],
        'timeoutMillis': 500,
      }),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'INVALID_REACHABILITY_REQUEST',
        ),
      ),
    );
  });
}
