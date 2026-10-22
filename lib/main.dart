import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';
import 'package:spy_dev_det/features/onboarding/application/onboarding_controller.dart';
import 'package:spy_dev_det/features/onboarding/data/onboarding_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/application/history_preferences_controller.dart';
import 'package:spy_dev_det/features/settings/application/theme_controller.dart';
import 'package:spy_dev_det/features/settings/data/history_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/data/theme_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/history_preferences.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeRepository = SharedThemePreferencesRepository();
  final historyRepository = SharedHistoryPreferencesRepository();
  final onboardingRepository = SharedOnboardingPreferencesRepository();
  ThemePreferences initialTheme;
  HistoryPreferences initialHistoryPreferences;
  bool initialOnboardingCompleted;
  try {
    initialTheme = await themeRepository.load();
  } on Object {
    initialTheme = const ThemePreferences();
  }
  try {
    initialHistoryPreferences = await historyRepository.load();
  } on Object {
    initialHistoryPreferences = const HistoryPreferences();
  }
  try {
    initialOnboardingCompleted = await onboardingRepository.isCompleted();
  } on Object {
    initialOnboardingCompleted = false;
  }
  runApp(
    ProviderScope(
      overrides: [
        themePreferencesRepositoryProvider.overrideWithValue(themeRepository),
        initialThemePreferencesProvider.overrideWithValue(initialTheme),
        historyPreferencesRepositoryProvider.overrideWithValue(
          historyRepository,
        ),
        initialHistoryPreferencesProvider.overrideWithValue(
          initialHistoryPreferences,
        ),
        onboardingPreferencesRepositoryProvider.overrideWithValue(
          onboardingRepository,
        ),
        initialOnboardingCompletedProvider.overrideWithValue(
          initialOnboardingCompleted,
        ),
      ],
      child: const SpyDevDetApp(),
    ),
  );
}
