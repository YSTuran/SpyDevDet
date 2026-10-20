import 'dart:async';

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
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/settings/application/theme_controller.dart';
import 'package:spy_dev_det/features/settings/data/theme_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

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
    await tester.drag(find.byType(ListView), const Offset(0, -160));
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

  testWidgets('tarama sırasında ağ değişirse sonucu kaydetmez', (tester) async {
    await tester.pumpWidget(_testApp(repository: _ChangingNetworkRepository()));

    await tester.tap(find.text('Yerel ağı tara'));
    for (var index = 0; index < 5; index++) {
      await tester.pump(const Duration(milliseconds: 310));
    }

    expect(
      find.text(
        'Ağ bağlantısı tarama sırasında değişti. Sonuçlar kaydedilmedi.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tamamlanmış taramayı eski ağ kontrolü geçersiz kılmaz', (
    tester,
  ) async {
    final networkRepository = _RacingNetworkRepository();
    final historyRepository = _TestHistoryRepository();
    await tester.pumpWidget(
      _testApp(
        repository: networkRepository,
        scanner: const _DelayedScanner(),
        historyRepository: historyRepository,
      ),
    );

    await tester.tap(find.text('Yerel ağı tara'));
    await tester.pump(const Duration(seconds: 2));
    expect(networkRepository.requestCount, 2);

    await tester.pump(const Duration(milliseconds: 200));
    expect(historyRepository.recordCount, 1);
    expect(find.text('Tarama tamamlandı • geçmişe kaydedildi'), findsOneWidget);

    networkRepository.completeStaleCheckWithChangedNetwork();
    await tester.pump();

    expect(historyRepository.recordCount, 1);
    expect(find.text('Tarama tamamlandı • geçmişe kaydedildi'), findsOneWidget);
    expect(
      find.text(
        'Ağ bağlantısı tarama sırasında değişti. Sonuçlar kaydedilmedi.',
      ),
      findsNothing,
    );
  });

  testWidgets('tema varsayılanı aydınlık Material ve seçimler kalıcıdır', (
    tester,
  ) async {
    final themeRepository = _TestThemePreferencesRepository();
    await tester.pumpWidget(_testApp(themeRepository: themeRepository));
    await tester.pump();

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(themeRepository.current.preset, ColorThemePreset.material);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karanlık'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Okyanus').last);
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(themeRepository.current.mode, AppThemeMode.dark);
    expect(themeRepository.current.preset, ColorThemePreset.ocean);
  });

  testWidgets('geniş ekranda NavigationRail kullanır', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(themeRepository: _TestThemePreferencesRepository()),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

Widget _testApp({
  NetworkInfoRepository? repository,
  DeviceScanner? scanner,
  _TestHistoryRepository? historyRepository,
  ThemePreferencesRepository? themeRepository,
}) {
  return ProviderScope(
    overrides: [
      networkInfoRepositoryProvider.overrideWithValue(
        repository ?? const _TestNetworkRepository(),
      ),
      deviceScannerProvider.overrideWithValue(
        scanner ?? const FakeDeviceScanner(),
      ),
      scanHistoryRepositoryProvider.overrideWithValue(
        historyRepository ?? _TestHistoryRepository(),
      ),
      if (themeRepository != null)
        themePreferencesRepositoryProvider.overrideWithValue(themeRepository),
    ],
    child: const SpyDevDetApp(),
  );
}

class _TestThemePreferencesRepository implements ThemePreferencesRepository {
  ThemePreferences current = const ThemePreferences();

  @override
  Future<ThemePreferences> load() async => current;

  @override
  Future<void> save(ThemePreferences preferences) async {
    current = preferences;
  }
}

class _TestHistoryRepository implements ScanHistoryRepository {
  final Set<String> _seen = {};
  var recordCount = 0;

  @override
  Future<List<DeviceObservation>> recordCompletedScan(
    CompletedScanRecord record,
  ) async {
    recordCount++;
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
  Future<void> clearAllData() async {}

  @override
  Future<void> deleteSession(int sessionId) async {}

  @override
  Future<List<ScanHistorySummary>> getHistory({
    int limit = 50,
    String? networkKey,
  }) async => const [];

  @override
  Future<List<NetworkProfileSummary>> getNetworkProfiles() async => const [];

  @override
  Future<ScanHistoryDetails?> getDetails(int sessionId) async => null;

  @override
  Future<void> updateDeviceProfile({
    required String stableKey,
    required bool isKnown,
    required String? customName,
    required String? note,
    bool? isOwned,
    DeviceCategory? categoryOverride,
    bool clearCategoryOverride = false,
  }) async {}

  @override
  Future<void> renameNetworkProfile({
    required String networkKey,
    required String? customName,
  }) async {}
}

class _DelayedScanner implements DeviceScanner {
  const _DelayedScanner();

  @override
  Stream<ScanEvent> scan(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async* {
    yield ScanStarted(totalTargets: plan.targets.length);
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    if (cancellationToken.isCancelled) {
      yield const ScanCancelled();
      return;
    }
    yield ScanCompleted(
      completedTargets: plan.targets.length,
      elapsed: const Duration(milliseconds: 2100),
    );
  }
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

class _ChangingNetworkRepository implements NetworkInfoRepository {
  var _requestCount = 0;

  @override
  Future<NetworkSnapshot> getCurrentNetwork() async {
    _requestCount++;
    return NetworkSnapshot(
      localIpv4: _requestCount == 1 ? '192.168.1.24' : '192.168.1.25',
      prefixLength: 24,
      interfaceName: 'wlan0',
      gatewayIpv4: '192.168.1.1',
      isWifi: true,
      isVpn: false,
    );
  }
}

class _RacingNetworkRepository implements NetworkInfoRepository {
  final Completer<NetworkSnapshot> _staleCheck = Completer();
  var requestCount = 0;

  @override
  Future<NetworkSnapshot> getCurrentNetwork() {
    requestCount++;
    if (requestCount == 2) {
      return _staleCheck.future;
    }
    return Future.value(_primaryNetwork);
  }

  void completeStaleCheckWithChangedNetwork() {
    _staleCheck.complete(
      const NetworkSnapshot(
        localIpv4: '192.168.1.25',
        prefixLength: 24,
        interfaceName: 'wlan0',
        gatewayIpv4: '192.168.1.1',
        isWifi: true,
        isVpn: false,
      ),
    );
  }

  static const _primaryNetwork = NetworkSnapshot(
    localIpv4: '192.168.1.24',
    prefixLength: 24,
    interfaceName: 'wlan0',
    gatewayIpv4: '192.168.1.1',
    isWifi: true,
    isVpn: false,
  );
}
