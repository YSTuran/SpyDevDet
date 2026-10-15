import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';
import 'package:spy_dev_det/features/network/domain/network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/data/fake_device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

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

    expect(find.text('Tarama tamamlandı • 3 cihaz • 3 yeni'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gözlemlenen cihazlar (3)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Gözlemlenen cihazlar (3)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Demo yönlendirici'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Demo yönlendirici'), findsOneWidget);
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
      scanHistoryRepositoryProvider.overrideWithValue(_TestHistoryRepository()),
    ],
    child: const SpyDevDetApp(),
  );
}

class _TestHistoryRepository implements ScanHistoryRepository {
  final Set<String> _seen = {};

  @override
  Future<List<DeviceObservation>> recordCompletedScan(
    CompletedScanRecord record,
  ) async {
    return record.devices
        .map((device) {
          final stableKey = 'test:${device.ipAddress}';
          final isNew = _seen.add(stableKey);
          return device.copyWith(
            stableKey: stableKey,
            familiarity: isNew
                ? DeviceFamiliarity.newDevice
                : DeviceFamiliarity.seenBefore,
            firstSeenAt: record.report.completedAt,
            lastSeenAt: record.report.completedAt,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> deleteSession(int sessionId) async {}

  @override
  Future<List<ScanHistorySummary>> getHistory({int limit = 50}) async =>
      const [];

  @override
  Future<ScanHistoryDetails?> getDetails(int sessionId) async => null;

  @override
  Future<void> updateDeviceProfile({
    required String stableKey,
    required bool isKnown,
    required String? customName,
    required String? note,
  }) async {}
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
