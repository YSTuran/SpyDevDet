import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/settings/application/theme_controller.dart';
import 'package:spy_dev_det/features/settings/data/theme_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

void main() {
  test('ardışık kayıt hatalarında son kalıcı temaya döner', () async {
    final container = ProviderContainer(
      overrides: [
        themePreferencesRepositoryProvider.overrideWithValue(
          _FailingThemePreferencesRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(themeControllerProvider.notifier);

    final first = expectLater(
      controller.selectMode(AppThemeMode.dark),
      throwsA(isA<StateError>()),
    );
    final second = expectLater(
      controller.selectPreset(ColorThemePreset.ocean),
      throwsA(isA<StateError>()),
    );
    await Future.wait([first, second]);

    final state = container.read(themeControllerProvider);
    expect(state.mode, AppThemeMode.light);
    expect(state.preset, ColorThemePreset.material);
  });
}

class _FailingThemePreferencesRepository implements ThemePreferencesRepository {
  @override
  Future<ThemePreferences> load() async => const ThemePreferences();

  @override
  Future<void> save(ThemePreferences preferences) async {
    await Future<void>.delayed(Duration.zero);
    throw StateError('storage unavailable');
  }
}
