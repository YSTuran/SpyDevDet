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

enum ColorThemePreset {
  material,
  ocean,
  emerald,
  violet,
  amber,
  rose,
  coral,
  indigo,
  graphite,
}

extension ColorThemePresetText on ColorThemePreset {
  String get label => switch (this) {
    ColorThemePreset.material => 'Material',
    ColorThemePreset.ocean => 'Okyanus',
    ColorThemePreset.emerald => 'Zümrüt',
    ColorThemePreset.violet => 'Menekşe',
    ColorThemePreset.amber => 'Kehribar',
    ColorThemePreset.rose => 'Gül',
    ColorThemePreset.coral => 'Mercan',
    ColorThemePreset.indigo => 'İndigo',
    ColorThemePreset.graphite => 'Grafit',
  };

  String get description => switch (this) {
    ColorThemePreset.material => 'Dengeli turkuaz',
    ColorThemePreset.ocean => 'Sakin mavi',
    ColorThemePreset.emerald => 'Doğal yeşil',
    ColorThemePreset.violet => 'Yumuşak mor',
    ColorThemePreset.amber => 'Sıcak kehribar',
    ColorThemePreset.rose => 'Zarif pembe',
    ColorThemePreset.coral => 'Canlı ve sıcak',
    ColorThemePreset.indigo => 'Derin mavi-mor',
    ColorThemePreset.graphite => 'Sade ve nötr',
  };

  Color get seedColor => switch (this) {
    ColorThemePreset.material => const Color(0xFF006A6A),
    ColorThemePreset.ocean => const Color(0xFF0061A4),
    ColorThemePreset.emerald => const Color(0xFF386A20),
    ColorThemePreset.violet => const Color(0xFF6750A4),
    ColorThemePreset.amber => const Color(0xFF8B5000),
    ColorThemePreset.rose => const Color(0xFF9C3D64),
    ColorThemePreset.coral => const Color(0xFFB14D3D),
    ColorThemePreset.indigo => const Color(0xFF4455A5),
    ColorThemePreset.graphite => const Color(0xFF52606D),
  };

  List<Color> get previewColors => switch (this) {
    ColorThemePreset.material => const [
      Color(0xFF006A6A),
      Color(0xFF4A6363),
      Color(0xFF4B607C),
    ],
    ColorThemePreset.ocean => const [
      Color(0xFF0061A4),
      Color(0xFF006874),
      Color(0xFF4D5F7D),
    ],
    ColorThemePreset.emerald => const [
      Color(0xFF386A20),
      Color(0xFF006B58),
      Color(0xFF53643E),
    ],
    ColorThemePreset.violet => const [
      Color(0xFF6750A4),
      Color(0xFF7D5260),
      Color(0xFF625B71),
    ],
    ColorThemePreset.amber => const [
      Color(0xFF8B5000),
      Color(0xFF765A00),
      Color(0xFF6D5E3F),
    ],
    ColorThemePreset.rose => const [
      Color(0xFF9C3D64),
      Color(0xFF7D5260),
      Color(0xFF6D5677),
    ],
    ColorThemePreset.coral => const [
      Color(0xFFB14D3D),
      Color(0xFF8C4A3F),
      Color(0xFF76564F),
    ],
    ColorThemePreset.indigo => const [
      Color(0xFF4455A5),
      Color(0xFF5B5F97),
      Color(0xFF76546F),
    ],
    ColorThemePreset.graphite => const [
      Color(0xFF52606D),
      Color(0xFF4F6268),
      Color(0xFF625B71),
    ],
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
