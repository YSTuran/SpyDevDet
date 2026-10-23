import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';
import 'package:spy_dev_det/features/network/domain/network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/reference_scan_comparison.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/onboarding/application/onboarding_controller.dart';
import 'package:spy_dev_det/features/onboarding/data/onboarding_preferences_repository.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/data/fake_device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/settings/application/theme_controller.dart';
import 'package:spy_dev_det/features/settings/application/history_preferences_controller.dart';
import 'package:spy_dev_det/features/settings/data/history_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/data/theme_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/history_preferences.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

void main() {
  testWidgets('ilk kullanım rehberi tamamlanınca ana uygulamayı açar', (
    tester,
  ) async {
    final onboardingRepository = _TestOnboardingPreferencesRepository();
    await tester.pumpWidget(
      _testApp(
        onboardingCompleted: false,
        onboardingRepository: onboardingRepository,
      ),
    );

    expect(find.text('Yerel ağı görünür hâle getir'), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('İleri'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Değişiklikleri karşılaştır'), findsOneWidget);
    await tester.tap(find.text('Uygulamaya başla'));
    await tester.pumpAndSettle();

    expect(onboardingRepository.completed, isTrue);
    expect(find.text('Yerel ağı tara'), findsOneWidget);
  });

  testWidgets('tarama cihazları aşamalı olarak gösterir', (tester) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('Yerel ağı tara'), findsOneWidget);
    expect(find.text('Ağındaki cihazları keşfet'), findsOneWidget);

    await tester.tap(find.text('Yerel ağı tara'));
    await tester.pump();

    expect(find.text('Taramayı durdur'), findsOneWidget);
    expect(find.text('3 yerel adres taranıyor'), findsOneWidget);

    for (var index = 0; index < 4; index++) {
      await tester.pump(const Duration(milliseconds: 310));
    }

    expect(
      find.text('Tarama tamamlandı • 3 cihaz • 3 uygulamada ilk kez'),
      findsOneWidget,
    );
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
    expect(ColorThemePreset.values, hasLength(9));
    expect(find.text('İndigo'), findsOneWidget);
    expect(find.text('Grafit'), findsOneWidget);
    await tester.tap(find.text('Karanlık'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Okyanus').last);
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(themeRepository.current.mode, AppThemeMode.dark);
    expect(themeRepository.current.preset, ColorThemePreset.ocean);
  });

  testWidgets('kayıtlı tema ilk Flutter karesinde uygulanır', (tester) async {
    const initialTheme = ThemePreferences(
      mode: AppThemeMode.dark,
      preset: ColorThemePreset.violet,
    );

    await tester.pumpWidget(
      _testApp(
        themeRepository: _TestThemePreferencesRepository(),
        initialTheme: initialTheme,
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.theme?.colorScheme.brightness, Brightness.light);
    expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
  });

  testWidgets('tema kaydı başarısızsa son kalıcı seçime döner', (tester) async {
    await tester.pumpWidget(
      _testApp(themeRepository: _FailingThemePreferencesRepository()),
    );
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Karanlık'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.text('Tema tercihi kaydedilemedi'), findsOneWidget);
  });

  testWidgets('dar ekranda tema ve cihaz filtreleri taşmadan yerleşir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(themeRepository: _TestThemePreferencesRepository()),
    );
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Aydınlık'), findsOneWidget);
    expect(find.text('Karanlık'), findsOneWidget);
    expect(find.text('Sistem'), findsOneWidget);

    await tester.tap(find.text('Tarama'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yerel ağı tara'));
    for (var index = 0; index < 5; index++) {
      await tester.pump(const Duration(milliseconds: 310));
    }
    await tester.scrollUntilVisible(
      find.text('Cihazlarda ara'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    final filterTop = tester.getTopLeft(find.text('Filtre')).dy;
    final sortTop = tester.getTopLeft(find.text('Sırala')).dy;
    expect(sortTop, greaterThan(filterTop));
  });

  final layoutScenarios = <({String name, Size size, double textScale})>[
    (name: 'küçük Android', size: const Size(360, 800), textScale: 2),
    (name: 'orta Android', size: const Size(412, 915), textScale: 1.5),
    (name: 'küçük pencere', size: const Size(800, 600), textScale: 2),
    (name: 'masaüstü', size: const Size(1280, 720), textScale: 1.5),
    (name: 'geniş masaüstü', size: const Size(1920, 1080), textScale: 1),
  ];
  for (final scenario in layoutScenarios) {
    testWidgets('${scenario.name} görünümünde büyük metin taşma oluşturmuyor', (
      tester,
    ) async {
      _configureSurface(
        tester,
        size: scenario.size,
        textScale: scenario.textScale,
      );

      await tester.pumpWidget(
        _testApp(themeRepository: _TestThemePreferencesRepository()),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Ayarlar').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Görünüm modu'), findsOneWidget);
    });
  }

  testWidgets('iki kat metin ölçeğinde tarama sonuçları taşmadan gösterilir', (
    tester,
  ) async {
    _configureSurface(tester, size: const Size(360, 800), textScale: 2);
    await tester.pumpWidget(_testApp());

    await tester.scrollUntilVisible(
      find.text('Tarama modu'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_semanticsWithLabel('Ayrıntılı tarama modu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Yerel ağı tara'),
      -160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Yerel ağı tara'));
    for (var index = 0; index < 5; index++) {
      await tester.pump(const Duration(milliseconds: 310));
    }
    await tester.scrollUntilVisible(
      find.text('Demo yönlendirici'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
    expect(
      _semanticsWithLabel(RegExp(r'Demo yönlendirici.+Ayrıntıları aç')),
      findsOneWidget,
    );
  });

  testWidgets('tarama durumu ve ilerlemesi ekran okuyucuya açıklanır', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    final status = tester.widget<Semantics>(
      _semanticsWithLabel(
        'Tarama durumu: Yerel ağ taraması başlatılmayı bekliyor',
      ),
    );
    expect(status.properties.liveRegion, isTrue);
    final progress = tester.widget<Semantics>(
      _semanticsWithLabel('Tarama ilerlemesi'),
    );
    expect(progress.properties.value, 'Yüzde 0');
  });

  testWidgets('masaüstünde klavye odağı etkileşimli öğelere ulaşır', (
    tester,
  ) async {
    _configureSurface(tester, size: const Size(1200, 800));
    await tester.pumpWidget(_testApp());

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, isNotNull);
  });

  testWidgets('geri tuşu önce tarama sekmesine döner', (tester) async {
    await tester.pumpWidget(
      _testApp(themeRepository: _TestThemePreferencesRepository()),
    );
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Yerel ağı tara'), findsOneWidget);
    expect(find.text('Görünüm modu'), findsNothing);
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

  testWidgets('saklama sınırını düşürmeden önce onay ister', (tester) async {
    final historyPreferences = _TestHistoryPreferencesRepository();
    await tester.pumpWidget(
      _testApp(
        themeRepository: _TestThemePreferencesRepository(),
        historyPreferencesRepository: historyPreferences,
      ),
    );
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tarama geçmişi'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('100 tarama'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('100 tarama'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25 tarama').last);
    await tester.pumpAndSettle();

    expect(find.text('Eski taramalar temizlensin mi?'), findsOneWidget);
    await tester.tap(find.text('Sınırı uygula'));
    await tester.pumpAndSettle();
    expect(historyPreferences.current.maxScansPerNetwork, 25);
  });
}

void _configureSurface(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Finder _semanticsWithLabel(Pattern label) => find.byWidgetPredicate((widget) {
  if (widget is! Semantics) return false;
  final actual = widget.properties.label;
  return switch (label) {
    String() => actual == label,
    RegExp() => actual != null && label.hasMatch(actual),
    _ => false,
  };
});

Widget _testApp({
  NetworkInfoRepository? repository,
  DeviceScanner? scanner,
  _TestHistoryRepository? historyRepository,
  ThemePreferencesRepository? themeRepository,
  HistoryPreferencesRepository? historyPreferencesRepository,
  ThemePreferences? initialTheme,
  bool onboardingCompleted = true,
  OnboardingPreferencesRepository? onboardingRepository,
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
      initialOnboardingCompletedProvider.overrideWithValue(onboardingCompleted),
      if (onboardingRepository != null)
        onboardingPreferencesRepositoryProvider.overrideWithValue(
          onboardingRepository,
        ),
      if (themeRepository != null)
        themePreferencesRepositoryProvider.overrideWithValue(themeRepository),
      if (historyPreferencesRepository != null)
        historyPreferencesRepositoryProvider.overrideWithValue(
          historyPreferencesRepository,
        ),
      if (initialTheme != null)
        initialThemePreferencesProvider.overrideWithValue(initialTheme),
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

class _FailingThemePreferencesRepository implements ThemePreferencesRepository {
  @override
  Future<ThemePreferences> load() async => const ThemePreferences();

  @override
  Future<void> save(ThemePreferences preferences) =>
      Future<void>.error(StateError('Test depolama hatası'));
}

class _TestHistoryPreferencesRepository
    implements HistoryPreferencesRepository {
  HistoryPreferences current = const HistoryPreferences();

  @override
  Future<HistoryPreferences> load() async => current;

  @override
  Future<void> save(HistoryPreferences preferences) async {
    current = preferences;
  }
}

class _TestOnboardingPreferencesRepository
    implements OnboardingPreferencesRepository {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}

class _TestHistoryRepository implements ScanHistoryRepository {
  final Set<String> _seen = {};
  var recordCount = 0;

  @override
  Future<RecordedScanResult> recordCompletedScan(
    CompletedScanRecord record,
  ) async {
    recordCount++;
    final devices = record.devices
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
    return RecordedScanResult(
      sessionId: recordCount,
      networkKey: record.networkKey,
      devices: devices,
      referenceComparison: const ReferenceScanComparison.noBaseline(),
    );
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
  Future<List<KnownDeviceSummary>> getKnownDevices() async => const [];

  @override
  Future<ScanHistoryDetails?> getDetails(int sessionId) async => null;

  @override
  Future<DeviceTimeline?> getDeviceTimeline(String stableKey) async => null;

  @override
  Future<SelectedScanComparison> compareSessions({
    required int firstSessionId,
    required int secondSessionId,
  }) async => throw StateError('Test karşılaştırması tanımlanmadı');

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

  @override
  Future<void> setReferenceScan(int sessionId) async {}

  @override
  Future<void> forgetDevice(String stableKey) async {}

  @override
  Future<void> deleteNetworkData(String networkKey) async {}

  @override
  Future<void> applyRetentionLimit() async {}
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
