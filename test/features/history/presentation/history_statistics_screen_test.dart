import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/network_history_statistics.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_statistics_screen.dart';

void main() {
  testWidgets('istatistik ekranı dar ekranda büyük metinle taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final statistics = NetworkHistoryStatistics.fromRecords(
      history: List.generate(
        12,
        (index) => _history(
          id: 12 - index,
          minute: 55 - (index * 5),
          devices: 2 + (index % 8),
        ),
      ),
      networks: [
        NetworkProfileSummary(
          networkKey: 'home',
          firstSeenAt: DateTime(2026),
          lastSeenAt: DateTime(2026),
          scanCount: 12,
          lastDeviceCount: 5,
        ),
      ],
      devices: [
        KnownDeviceSummary(
          stableKey: 'pc',
          displayName: 'Ev bilgisayarı',
          isKnown: true,
          isOwned: true,
          firstSeenAt: DateTime(2026),
          lastSeenAt: DateTime(2026),
          lastIpAddress: '192.168.1.10',
          observationCount: 12,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStatisticsProvider(null)
              .overrideWith((ref) async => statistics),
          networkProfilesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: HistoryStatisticsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ağ geçmişi istatistikleri'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cihaz sayısı eğilimi'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cihaz sayısı eğilimi'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('En sık gözlemlenen cihazlar'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ev bilgisayarı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ScanHistorySummary _history({
  required int id,
  required int minute,
  required int devices,
}) {
  final startedAt = DateTime(2026, 1, 1, 12, minute);
  return ScanHistorySummary(
    id: id,
    networkKey: 'home',
    startedAt: startedAt,
    completedAt: startedAt.add(const Duration(seconds: 2)),
    isPartial: false,
    totalDeviceCount: devices,
    newDeviceCount: id == 1 ? devices : 0,
    missingDevices: const [],
    elapsed: const Duration(seconds: 2),
    methods: const {},
  );
}
