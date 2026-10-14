import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';
import 'package:spy_dev_det/features/network/domain/network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/data/fake_device_scanner.dart';

void main() {
  testWidgets('tarama cihazları aşamalı olarak gösterir', (tester) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('Yerel ağı tara'), findsOneWidget);
    expect(find.text('Gözlemlenen cihazlar (0)'), findsOneWidget);

    await tester.tap(find.text('Yerel ağı tara'));
    await tester.pump();

    expect(find.text('Taramayı durdur'), findsOneWidget);
    expect(find.text('3 yerel adres taranıyor'), findsOneWidget);

    for (var index = 0; index < 4; index++) {
      await tester.pump(const Duration(milliseconds: 310));
    }

    expect(find.text('Demo yönlendirici'), findsOneWidget);
    expect(find.text('Gözlemlenen cihazlar (3)'), findsOneWidget);
    expect(
      find.text('Tarama tamamlandı • 3 cihaz gözlemlendi'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Demo bilgisayar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Demo bilgisayar'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bilinmeyen demo cihaz'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bilinmeyen demo cihaz'), findsOneWidget);
  });

  testWidgets('devam eden tarama iptal edilebilir', (tester) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.text('Yerel ağı tara'));
    await tester.pump();
    await tester.tap(find.text('Taramayı durdur'));
    await tester.pump();

    expect(
      find.text('Tarama kullanıcı tarafından iptal edildi'),
      findsOneWidget,
    );
    expect(find.text('Yerel ağı tara'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 310));
  });

  testWidgets('Wi-Fi hatasını anlaşılır biçimde gösterir', (tester) async {
    await tester.pumpWidget(_testApp(repository: const _FailingRepository()));

    await tester.tap(find.text('Yerel ağı tara'));
    await tester.pump();

    expect(
      find.text('Yerel ağ taraması için Wi-Fi bağlantısı gereklidir.'),
      findsOneWidget,
    );
  });
}

Widget _testApp({NetworkInfoRepository? repository}) {
  return ProviderScope(
    overrides: [
      networkInfoRepositoryProvider.overrideWithValue(
        repository ?? const _TestNetworkRepository(),
      ),
      deviceScannerProvider.overrideWithValue(const FakeDeviceScanner()),
    ],
    child: const SpyDevDetApp(),
  );
}

class _TestNetworkRepository implements NetworkInfoRepository {
  const _TestNetworkRepository();

  @override
  Future<NetworkSnapshot> getCurrentNetwork() async {
    return const NetworkSnapshot(
      localIpv4: '192.168.1.24',
      prefixLength: 24,
      interfaceName: 'wlan0',
      gatewayIpv4: '192.168.1.1',
      isWifi: true,
      isVpn: false,
    );
  }
}

class _FailingRepository implements NetworkInfoRepository {
  const _FailingRepository();

  @override
  Future<NetworkSnapshot> getCurrentNetwork() {
    throw const NetworkInfoException(
      'WIFI_REQUIRED',
      'Yerel ağ taraması için Wi-Fi bağlantısı gereklidir.',
    );
  }
}
