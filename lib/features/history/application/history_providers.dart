import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/data/app_database.dart';
import 'package:spy_dev_det/features/history/data/drift_scan_history_repository.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/settings/application/history_preferences_controller.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>(
  (ref) => DriftScanHistoryRepository(
    ref.watch(appDatabaseProvider),
    maxSessionsPerNetwork: ref
        .watch(historyPreferencesControllerProvider)
        .maxScansPerNetwork,
  ),
);

final scanHistoryProvider =
    FutureProvider.autoDispose<List<ScanHistorySummary>>(
      (ref) => ref.watch(scanHistoryRepositoryProvider).getHistory(),
    );

final networkProfilesProvider =
    FutureProvider.autoDispose<List<NetworkProfileSummary>>(
      (ref) => ref.watch(scanHistoryRepositoryProvider).getNetworkProfiles(),
    );

final knownDevicesProvider =
    FutureProvider.autoDispose<List<KnownDeviceSummary>>(
      (ref) => ref.watch(scanHistoryRepositoryProvider).getKnownDevices(),
    );

final networkScanHistoryProvider = FutureProvider.autoDispose
    .family<List<ScanHistorySummary>, String>(
      (ref, networkKey) => ref
          .watch(scanHistoryRepositoryProvider)
          .getHistory(networkKey: networkKey),
    );

final scanHistoryDetailsProvider = FutureProvider.autoDispose
    .family<ScanHistoryDetails?, int>(
      (ref, sessionId) =>
          ref.watch(scanHistoryRepositoryProvider).getDetails(sessionId),
    );

final deviceTimelineProvider = FutureProvider.autoDispose
    .family<DeviceTimeline?, String>(
      (ref, stableKey) =>
          ref.watch(scanHistoryRepositoryProvider).getDeviceTimeline(stableKey),
    );
