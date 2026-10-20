import 'package:shared_preferences/shared_preferences.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

abstract interface class ThemePreferencesRepository {
  Future<ThemePreferences> load();

  Future<void> save(ThemePreferences preferences);
}

class SharedThemePreferencesRepository implements ThemePreferencesRepository {
  SharedThemePreferencesRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _modeKey = 'appearance.theme_mode';
  static const _presetKey = 'appearance.color_preset';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ThemePreferences> load() async {
    final modeName = await _preferences.getString(_modeKey);
    final presetName = await _preferences.getString(_presetKey);
    return ThemePreferences(
      mode: _byName(AppThemeMode.values, modeName) ?? AppThemeMode.light,
      preset:
          _byName(ColorThemePreset.values, presetName) ??
          ColorThemePreset.material,
    );
  }

  @override
  Future<void> save(ThemePreferences preferences) async {
    await _preferences.setString(_modeKey, preferences.mode.name);
    await _preferences.setString(_presetKey, preferences.preset.name);
  }

  T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}
