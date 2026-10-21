import 'package:shared_preferences/shared_preferences.dart';
import 'package:spy_dev_det/features/settings/domain/history_preferences.dart';

abstract interface class HistoryPreferencesRepository {
  Future<HistoryPreferences> load();

  Future<void> save(HistoryPreferences preferences);
}

class SharedHistoryPreferencesRepository
    implements HistoryPreferencesRepository {
  SharedHistoryPreferencesRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _retentionKey = 'history.max_scans_per_network';

  final SharedPreferencesAsync _preferences;

  @override
  Future<HistoryPreferences> load() async {
    final savedLimit = await _preferences.getInt(_retentionKey);
    return HistoryPreferences(
      maxScansPerNetwork:
          HistoryPreferences.supportedLimits.contains(savedLimit)
          ? savedLimit!
          : 100,
    );
  }

  @override
  Future<void> save(HistoryPreferences preferences) =>
      _preferences.setInt(_retentionKey, preferences.maxScansPerNetwork);
}
