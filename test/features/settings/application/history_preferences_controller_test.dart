import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/settings/application/history_preferences_controller.dart';
import 'package:spy_dev_det/features/settings/data/history_preferences_repository.dart';
import 'package:spy_dev_det/features/settings/domain/history_preferences.dart';

void main() {
  test('saklama sınırını günceller ve kalıcı depoya yazar', () async {
    final repository = _MemoryHistoryPreferencesRepository();
    final container = ProviderContainer(
      overrides: [
        historyPreferencesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(historyPreferencesControllerProvider.notifier)
        .selectRetentionLimit(25);

    expect(
      container.read(historyPreferencesControllerProvider).maxScansPerNetwork,
      25,
    );
    expect(repository.saved.maxScansPerNetwork, 25);
  });

  test('geçersiz saklama sınırını kabul etmez', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container
          .read(historyPreferencesControllerProvider.notifier)
          .selectRetentionLimit(10),
      throwsArgumentError,
    );
  });

  test('ardışık kayıt hatalarında son kalıcı saklama sınırına döner', () async {
    final container = ProviderContainer(
      overrides: [
        historyPreferencesRepositoryProvider.overrideWithValue(
          _FailingHistoryPreferencesRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      historyPreferencesControllerProvider.notifier,
    );

    final first = expectLater(
      controller.selectRetentionLimit(50),
      throwsA(isA<StateError>()),
    );
    final second = expectLater(
      controller.selectRetentionLimit(25),
      throwsA(isA<StateError>()),
    );
    await Future.wait([first, second]);

    expect(
      container.read(historyPreferencesControllerProvider).maxScansPerNetwork,
      100,
    );
  });
}

class _MemoryHistoryPreferencesRepository
    implements HistoryPreferencesRepository {
  HistoryPreferences saved = const HistoryPreferences();

  @override
  Future<HistoryPreferences> load() async => saved;

  @override
  Future<void> save(HistoryPreferences preferences) async {
    saved = preferences;
  }
}

class _FailingHistoryPreferencesRepository
    implements HistoryPreferencesRepository {
  @override
  Future<HistoryPreferences> load() async => const HistoryPreferences();

  @override
  Future<void> save(HistoryPreferences preferences) async {
    await Future<void>.delayed(Duration.zero);
    throw StateError('storage unavailable');
  }
}
