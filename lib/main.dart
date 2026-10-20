import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';
import 'package:spy_dev_det/features/settings/application/theme_controller.dart';
import 'package:spy_dev_det/features/settings/data/theme_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeRepository = SharedThemePreferencesRepository();
  ThemePreferences initialTheme;
  try {
    initialTheme = await themeRepository.load();
  } on Object {
    initialTheme = const ThemePreferences();
  }
  runApp(
    ProviderScope(
      overrides: [
        themePreferencesRepositoryProvider.overrideWithValue(themeRepository),
        initialThemePreferencesProvider.overrideWithValue(initialTheme),
      ],
      child: const SpyDevDetApp(),
    ),
  );
}
