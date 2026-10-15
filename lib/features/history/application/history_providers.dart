import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/data/app_database.dart';
import 'package:spy_dev_det/features/history/data/drift_scan_history_repository.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>(
  (ref) => DriftScanHistoryRepository(ref.watch(appDatabaseProvider)),
);

final scanHistoryProvider =
    FutureProvider.autoDispose<List<ScanHistorySummary>>(
      (ref) => ref.watch(scanHistoryRepositoryProvider).getHistory(),
    );

final scanHistoryDetailsProvider = FutureProvider.autoDispose
    .family<ScanHistoryDetails?, int>(
      (ref, sessionId) =>
          ref.watch(scanHistoryRepositoryProvider).getDetails(sessionId),
    );
