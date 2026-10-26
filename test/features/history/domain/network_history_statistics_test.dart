import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/domain/network_history_statistics.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';

void main() {
  test('geçmişten özet, eğilim ve sık görülen cihazları hesaplar', () {
    final statistics = NetworkHistoryStatistics.fromRecords(
      history: [
        _history(id: 3, minute: 10, devices: 6, newDevices: 1, missing: 0),
        _history(id: 2, minute: 5, devices: 4, newDevices: 0, missing: 1),
        _history(id: 1, minute: 0, devices: 2, newDevices: 2, missing: 0),
      ],
      networks: [
        NetworkProfileSummary(
          networkKey: 'home',
          firstSeenAt: DateTime(2026),
          lastSeenAt: DateTime(2026),
          scanCount: 3,
          lastDeviceCount: 6,
        ),
      ],
      devices: [
        KnownDeviceSummary(
          stableKey: 'pc',
          displayName: 'Bilgisayar',
          isKnown: true,
          isOwned: true,
          firstSeenAt: DateTime(2026),
          lastSeenAt: DateTime(2026),
          lastIpAddress: '192.168.1.10',
          observationCount: 3,
        ),
        KnownDeviceSummary(
          stableKey: 'unknown',
          displayName: 'Ağ cihazı',
          isKnown: false,
          isOwned: false,
          firstSeenAt: DateTime(2026),
          lastSeenAt: DateTime(2026),
          lastIpAddress: '192.168.1.20',
          observationCount: 1,
        ),
      ],
    );

    expect(statistics.totalScans, 3);
    expect(statistics.networkCount, 1);
    expect(statistics.averageDeviceCount, 4);
    expect(statistics.averageDuration, const Duration(seconds: 2));
    expect(statistics.totalNewDeviceObservations, 3);
    expect(statistics.totalMissingDeviceObservations, 1);
    expect(statistics.knownDeviceCount, 1);
    expect(statistics.unclassifiedDeviceCount, 1);
    expect(
      statistics.trend.map((point) => point.deviceCount),
      orderedEquals([2, 4, 6]),
    );
    expect(statistics.frequentDevices.first.stableKey, 'pc');
  });

  test('boş geçmiş sıfır değerli güvenli bir özet üretir', () {
    final statistics = NetworkHistoryStatistics.fromRecords(
      history: const [],
      networks: const [],
      devices: const [],
    );

    expect(statistics.isEmpty, isTrue);
    expect(statistics.averageDeviceCount, 0);
    expect(statistics.averageDuration, Duration.zero);
    expect(statistics.maximumTrendDeviceCount, 1);
  });
}

ScanHistorySummary _history({
  required int id,
  required int minute,
  required int devices,
  required int newDevices,
  required int missing,
}) {
  final startedAt = DateTime(2026, 1, 1, 12, minute);
  return ScanHistorySummary(
    id: id,
    networkKey: 'home',
    startedAt: startedAt,
    completedAt: startedAt.add(const Duration(seconds: 2)),
    isPartial: false,
    totalDeviceCount: devices,
    newDeviceCount: newDevices,
    missingDevices: List.generate(
      missing,
      (index) => MissingDeviceSummary(
        stableKey: 'missing-$index',
        displayName: 'Eksik cihaz',
        lastIpAddress: '192.168.1.${20 + index}',
      ),
    ),
    elapsed: const Duration(seconds: 2),
    methods: const {},
  );
}
