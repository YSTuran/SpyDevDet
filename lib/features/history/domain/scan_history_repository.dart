import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class CompletedScanRecord {
  const CompletedScanRecord({
    required this.networkKey,
    required this.report,
    required this.elapsed,
    required this.devices,
  });

  final String networkKey;
  final ScanReport report;
  final Duration elapsed;
  final List<DeviceObservation> devices;
}

class ScanHistorySummary {
  const ScanHistorySummary({
    required this.id,
    required this.networkKey,
    required this.startedAt,
    required this.completedAt,
    required this.isPartial,
    required this.totalDeviceCount,
    required this.newDeviceCount,
    required this.missingDevices,
    required this.elapsed,
    required this.methods,
  });

  final int id;
  final String networkKey;
  final DateTime startedAt;
  final DateTime completedAt;
  final bool isPartial;
  final int totalDeviceCount;
  final int newDeviceCount;
  final List<MissingDeviceSummary> missingDevices;
  final Duration elapsed;
  final Map<DiscoveryMethod, DiscoveryMethodResult> methods;
}

class MissingDeviceSummary {
  const MissingDeviceSummary({
    required this.stableKey,
    required this.displayName,
    required this.lastIpAddress,
  });

  final String stableKey;
  final String displayName;
  final String lastIpAddress;
}

class ScanHistoryDetails {
  const ScanHistoryDetails({required this.summary, required this.devices});

  final ScanHistorySummary summary;
  final List<DeviceObservation> devices;
}

abstract interface class ScanHistoryRepository {
  Future<List<DeviceObservation>> recordCompletedScan(
    CompletedScanRecord record,
  );

  Future<void> updateDeviceProfile({
    required String stableKey,
    required bool isKnown,
    required String? customName,
    required String? note,
  });

  Future<List<ScanHistorySummary>> getHistory({int limit = 50});

  Future<ScanHistoryDetails?> getDetails(int sessionId);

  Future<void> deleteSession(int sessionId);

  Future<void> clearHistory();

  Future<void> clearAllData();
}
