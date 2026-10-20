import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class CompletedScanRecord {
  const CompletedScanRecord({
    required this.networkKey,
    this.networkIdentityKeys = const [],
    required this.report,
    required this.elapsed,
    required this.devices,
  });

  final String networkKey;
  final List<String> networkIdentityKeys;
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
    this.scanMode = ScanMode.detailed,
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
  final ScanMode scanMode;
}

class NetworkProfileSummary {
  const NetworkProfileSummary({
    required this.networkKey,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.scanCount,
    required this.lastDeviceCount,
    this.customName,
  });

  final String networkKey;
  final String? customName;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int scanCount;
  final int lastDeviceCount;

  String get displayName =>
      customName?.trim().isNotEmpty == true ? customName!.trim() : 'Yerel ağ';

  bool get hasStrongIdentity =>
      networkKey.contains('|gateway-mac:') ||
      networkKey.contains('|gateway-service:');
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
    bool? isOwned,
    DeviceCategory? categoryOverride,
    bool clearCategoryOverride = false,
  });

  Future<List<ScanHistorySummary>> getHistory({
    int limit = 50,
    String? networkKey,
  });

  Future<List<NetworkProfileSummary>> getNetworkProfiles();

  Future<void> renameNetworkProfile({
    required String networkKey,
    required String? customName,
  });

  Future<ScanHistoryDetails?> getDetails(int sessionId);

  Future<void> deleteSession(int sessionId);

  Future<void> clearHistory();

  Future<void> clearAllData();
}
