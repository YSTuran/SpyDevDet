import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/app/app_theme.dart';
import 'package:spy_dev_det/app/home_shell.dart';
import 'package:spy_dev_det/features/onboarding/application/onboarding_controller.dart';
import 'package:spy_dev_det/features/onboarding/presentation/onboarding_screen.dart';
import 'package:spy_dev_det/features/settings/application/theme_controller.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

class SpyDevDetApp extends ConsumerWidget {
  const SpyDevDetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(themeControllerProvider);
    final onboardingCompleted = ref.watch(onboardingControllerProvider);
    return MaterialApp(
      title: 'SpyDevDet',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        brightness: Brightness.light,
        preset: preferences.preset,
      ),
      darkTheme: buildAppTheme(
        brightness: Brightness.dark,
        preset: preferences.preset,
      ),
      themeMode: preferences.mode.materialMode,
      home: onboardingCompleted
          ? const HomeShell()
          : OnboardingScreen(
              onCompleted: () =>
                  ref.read(onboardingControllerProvider.notifier).complete(),
            ),
    );
  }
}
