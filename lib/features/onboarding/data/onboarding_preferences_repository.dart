import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingPreferencesRepository {
  Future<bool> isCompleted();

  Future<void> markCompleted();
}

class SharedOnboardingPreferencesRepository
    implements OnboardingPreferencesRepository {
  SharedOnboardingPreferencesRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _completedKey = 'onboarding.completed.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isCompleted() async =>
      await _preferences.getBool(_completedKey) ?? false;

  @override
  Future<void> markCompleted() => _preferences.setBool(_completedKey, true);
}
