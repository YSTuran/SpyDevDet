import 'dart:math' as math;

import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';

class NetworkHistoryStatistics {
  NetworkHistoryStatistics._({
    required this.totalScans,
    required this.networkCount,
    required this.averageDeviceCount,
    required this.averageDuration,
    required this.totalNewDeviceObservations,
    required this.totalMissingDeviceObservations,
    required this.knownDeviceCount,
    required this.unclassifiedDeviceCount,
    required this.trend,
    required this.frequentDevices,
  });

  factory NetworkHistoryStatistics.fromRecords({
    required List<ScanHistorySummary> history,
    required List<NetworkProfileSummary> networks,
    required List<KnownDeviceSummary> devices,
    int trendLimit = 12,
    int frequentDeviceLimit = 5,
  }) {
    if (trendLimit < 1) {
      throw RangeError.value(trendLimit, 'trendLimit');
    }
    if (frequentDeviceLimit < 1) {
      throw RangeError.value(frequentDeviceLimit, 'frequentDeviceLimit');
    }

    final totalScans = history.length;
    final totalDevices = history.fold<int>(
      0,
      (sum, item) => sum + item.totalDeviceCount,
    );
    final totalDurationMicroseconds = history.fold<int>(
      0,
      (sum, item) => sum + item.elapsed.inMicroseconds,
    );
    final chronological = history
        .take(trendLimit)
        .toList(growable: false)
        .reversed
        .map(
          (item) => DeviceCountTrendPoint(
            completedAt: item.completedAt,
            deviceCount: item.totalDeviceCount,
            newDeviceCount: item.newDeviceCount,
            missingDeviceCount: item.missingDevices.length,
          ),
        )
        .toList(growable: false);
    final sortedDevices = [...devices]
      ..sort((first, second) {
        final countComparison = second.observationCount.compareTo(
          first.observationCount,
        );
        if (countComparison != 0) return countComparison;
        return second.lastSeenAt.compareTo(first.lastSeenAt);
      });

    return NetworkHistoryStatistics._(
      totalScans: totalScans,
      networkCount: networks.where((item) => item.scanCount > 0).length,
      averageDeviceCount: totalScans == 0 ? 0 : totalDevices / totalScans,
      averageDuration: totalScans == 0
          ? Duration.zero
          : Duration(microseconds: totalDurationMicroseconds ~/ totalScans),
      totalNewDeviceObservations: history.fold<int>(
        0,
        (sum, item) => sum + item.newDeviceCount,
      ),
      totalMissingDeviceObservations: history.fold<int>(
        0,
        (sum, item) => sum + item.missingDevices.length,
      ),
      knownDeviceCount: devices.where((item) => item.isKnown).length,
      unclassifiedDeviceCount: devices.where((item) => !item.isKnown).length,
      trend: List.unmodifiable(chronological),
      frequentDevices: List.unmodifiable(
        sortedDevices
            .where((item) => item.observationCount > 0)
            .take(frequentDeviceLimit),
      ),
    );
  }

  final int totalScans;
  final int networkCount;
  final double averageDeviceCount;
  final Duration averageDuration;
  final int totalNewDeviceObservations;
  final int totalMissingDeviceObservations;
  final int knownDeviceCount;
  final int unclassifiedDeviceCount;
  final List<DeviceCountTrendPoint> trend;
  final List<KnownDeviceSummary> frequentDevices;

  bool get isEmpty => totalScans == 0;

  int get maximumTrendDeviceCount => trend.fold<int>(
    1,
    (maximum, point) => math.max(maximum, point.deviceCount),
  );
}

class DeviceCountTrendPoint {
  const DeviceCountTrendPoint({
    required this.completedAt,
    required this.deviceCount,
    required this.newDeviceCount,
    required this.missingDeviceCount,
  });

  final DateTime completedAt;
  final int deviceCount;
  final int newDeviceCount;
  final int missingDeviceCount;
}
