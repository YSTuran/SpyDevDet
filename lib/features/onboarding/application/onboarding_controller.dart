import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/onboarding/data/onboarding_preferences_repository.dart';

final onboardingPreferencesRepositoryProvider =
    Provider<OnboardingPreferencesRepository>(
      (ref) => SharedOnboardingPreferencesRepository(),
    );

final initialOnboardingCompletedProvider = Provider<bool>((ref) => false);

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialOnboardingCompletedProvider);

  Future<void> complete() async {
    if (state) return;
    await ref.read(onboardingPreferencesRepositoryProvider).markCompleted();
    state = true;
  }
}
