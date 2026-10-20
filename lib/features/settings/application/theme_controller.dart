import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/settings/data/theme_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

final themePreferencesRepositoryProvider = Provider<ThemePreferencesRepository>(
  (ref) => SharedThemePreferencesRepository(),
);

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemePreferences>(ThemeController.new);

class ThemeController extends Notifier<ThemePreferences> {
  var _revision = 0;

  @override
  ThemePreferences build() {
    unawaited(_restore());
    return const ThemePreferences();
  }

  Future<void> _restore() async {
    final revision = _revision;
    try {
      final restored = await ref
          .read(themePreferencesRepositoryProvider)
          .load();
      if (revision == _revision) {
        state = restored;
      }
    } on Object {
      // Görünüm tercihleri kritik veri değildir; depolama kullanılamazsa
      // güvenli varsayılan olan Aydınlık + Material korunur.
    }
  }

  Future<void> selectMode(AppThemeMode mode) =>
      _update(state.copyWith(mode: mode));

  Future<void> selectPreset(ColorThemePreset preset) =>
      _update(state.copyWith(preset: preset));

  Future<void> _update(ThemePreferences next) async {
    _revision++;
    state = next;
    await ref.read(themePreferencesRepositoryProvider).save(next);
  }
}
