import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system }

extension AppThemeModeText on AppThemeMode {
  String get label => switch (this) {
    AppThemeMode.light => 'Aydınlık',
    AppThemeMode.dark => 'Karanlık',
    AppThemeMode.system => 'Sistem',
  };

  IconData get icon => switch (this) {
    AppThemeMode.light => Icons.light_mode_outlined,
    AppThemeMode.dark => Icons.dark_mode_outlined,
    AppThemeMode.system => Icons.brightness_auto_outlined,
  };

  ThemeMode get materialMode => switch (this) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}

enum ColorThemePreset { material, ocean, emerald, violet, amber }

extension ColorThemePresetText on ColorThemePreset {
  String get label => switch (this) {
    ColorThemePreset.material => 'Material',
    ColorThemePreset.ocean => 'Okyanus',
    ColorThemePreset.emerald => 'Zümrüt',
    ColorThemePreset.violet => 'Menekşe',
    ColorThemePreset.amber => 'Kehribar',
  };

  String get description => switch (this) {
    ColorThemePreset.material => 'Dengeli turkuaz',
    ColorThemePreset.ocean => 'Sakin mavi',
    ColorThemePreset.emerald => 'Doğal yeşil',
    ColorThemePreset.violet => 'Yumuşak mor',
    ColorThemePreset.amber => 'Sıcak kehribar',
  };

  Color get seedColor => switch (this) {
    ColorThemePreset.material => const Color(0xFF006A6A),
    ColorThemePreset.ocean => const Color(0xFF0061A4),
    ColorThemePreset.emerald => const Color(0xFF386A20),
    ColorThemePreset.violet => const Color(0xFF6750A4),
    ColorThemePreset.amber => const Color(0xFF8B5000),
  };
}

class ThemePreferences {
  const ThemePreferences({
    this.mode = AppThemeMode.light,
    this.preset = ColorThemePreset.material,
  });

  final AppThemeMode mode;
  final ColorThemePreset preset;

  ThemePreferences copyWith({AppThemeMode? mode, ColorThemePreset? preset}) =>
      ThemePreferences(mode: mode ?? this.mode, preset: preset ?? this.preset);
}
