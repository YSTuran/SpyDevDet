import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/settings/data/theme_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

final themePreferencesRepositoryProvider = Provider<ThemePreferencesRepository>(
  (ref) => SharedThemePreferencesRepository(),
);

final initialThemePreferencesProvider = Provider<ThemePreferences>(
  (ref) => const ThemePreferences(),
);

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemePreferences>(ThemeController.new);

class ThemeController extends Notifier<ThemePreferences> {
  var _revision = 0;
  Future<void> _saveQueue = Future<void>.value();

  @override
  ThemePreferences build() => ref.watch(initialThemePreferencesProvider);

  Future<void> selectMode(AppThemeMode mode) =>
      _update(state.copyWith(mode: mode));

  Future<void> selectPreset(ColorThemePreset preset) =>
      _update(state.copyWith(preset: preset));

  Future<void> _update(ThemePreferences next) async {
    final previous = state;
    final revision = ++_revision;
    state = next;
    final operation = _ignoreFailure(
      _saveQueue,
    ).then((_) => ref.read(themePreferencesRepositoryProvider).save(next));
    _saveQueue = operation;
    try {
      await operation;
    } on Object {
      if (revision == _revision) {
        state = previous;
      }
      rethrow;
    }
  }

  Future<void> _ignoreFailure(Future<void> operation) async {
    try {
      await operation;
    } on Object {
      // A later preference still needs to be persisted after an earlier
      // platform storage failure.
    }
  }
}
