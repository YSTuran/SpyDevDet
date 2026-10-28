import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/settings/data/history_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/history_preferences.dart';

final historyPreferencesRepositoryProvider =
    Provider<HistoryPreferencesRepository>(
      (ref) => SharedHistoryPreferencesRepository(),
    );

final initialHistoryPreferencesProvider = Provider<HistoryPreferences>(
  (ref) => const HistoryPreferences(),
);

final historyPreferencesControllerProvider =
    NotifierProvider<HistoryPreferencesController, HistoryPreferences>(
      HistoryPreferencesController.new,
    );

class HistoryPreferencesController extends Notifier<HistoryPreferences> {
  var _revision = 0;
  Future<void> _saveQueue = Future<void>.value();
  late HistoryPreferences _persisted;

  @override
  HistoryPreferences build() {
    _persisted = ref.watch(initialHistoryPreferencesProvider);
    return _persisted;
  }

  Future<void> selectRetentionLimit(int limit) {
    if (!HistoryPreferences.supportedLimits.contains(limit)) {
      throw ArgumentError.value(limit, 'limit');
    }
    return _update(state.copyWith(maxScansPerNetwork: limit));
  }

  Future<void> _update(HistoryPreferences next) async {
    final revision = ++_revision;
    state = next;
    final operation = _ignoreFailure(_saveQueue)
        .then((_) => ref.read(historyPreferencesRepositoryProvider).save(next));
    _saveQueue = operation;
    try {
      await operation;
      _persisted = next;
    } on Object {
      if (revision == _revision) {
        state = _persisted;
      }
      rethrow;
    }
  }

  Future<void> _ignoreFailure(Future<void> operation) async {
    try {
      await operation;
    } on Object {
      // A later preference must still be saved after an earlier failure.
    }
  }
}
