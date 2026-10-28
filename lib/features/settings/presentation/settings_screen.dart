import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/presentation/history_screen.dart';
import 'package:spy_dev_det/features/history/presentation/known_devices_screen.dart';
import 'package:spy_dev_det/features/history/presentation/network_profiles_screen.dart';
import 'package:spy_dev_det/features/onboarding/presentation/onboarding_screen.dart';
import 'package:spy_dev_det/features/settings/application/history_preferences_controller.dart';
import 'package:spy_dev_det/features/settings/application/theme_controller.dart';
import 'package:spy_dev_det/features/settings/domain/history_preferences.dart';
import 'package:spy_dev_det/features/settings/domain/theme_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final historyPreferences = ref.watch(historyPreferencesControllerProvider);
    final historyController = ref.read(
      historyPreferencesControllerProvider.notifier,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _AppearancePreview(preferences: preferences),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Görünüm modu',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Varsayılan görünüm aydınlıktır. İstersen karanlık '
                          'veya sistem ayarını kullanabilirsin.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale = MediaQuery.textScalerOf(context)
                                .scale(1);
                            final useVerticalOptions =
                                constraints.maxWidth < 440 && textScale > 1.3;
                            if (useVerticalOptions) {
                              return Column(
                                children: AppThemeMode.values
                                    .map(
                                      (mode) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: _ThemeModeOption(
                                          mode: mode,
                                          selected: mode == preferences.mode,
                                          onTap: () => _save(
                                            context,
                                            controller.selectMode(mode),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              );
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<AppThemeMode>(
                                showSelectedIcon: false,
                                segments: AppThemeMode.values
                                    .map(
                                      (mode) => ButtonSegment(
                                        value: mode,
                                        icon: constraints.maxWidth < 400
                                            ? null
                                            : Icon(mode.icon),
                                        label: Text(mode.label),
                                      ),
                                    )
                                    .toList(growable: false),
                                selected: {preferences.mode},
                                onSelectionChanged: (selection) => _save(
                                  context,
                                  controller.selectMode(selection.first),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Renk teması',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dokuz renk paletinin tümü aydınlık ve karanlık '
                          'görünüm için okunabilir tonlara dönüştürülür.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = constraints.maxWidth >= 620
                                ? (constraints.maxWidth - 24) / 3
                                : constraints.maxWidth >= 310
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: ColorThemePreset.values
                                  .map(
                                    (preset) => SizedBox(
                                      width: itemWidth,
                                      child: _ColorPresetTile(
                                        preset: preset,
                                        selected: preset == preferences.preset,
                                        onTap: () => _save(
                                          context,
                                          controller.selectPreset(preset),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarama geçmişi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Her ağ için saklanacak en yeni tarama sayısını '
                          'belirle. Seçili ağ referansı bu sınır içinde korunur.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ağ başına tarama sayısı',
                            prefixIcon: Icon(Icons.history),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: historyPreferences.maxScansPerNetwork,
                              items: HistoryPreferences.supportedLimits
                                  .map(
                                    (limit) => DropdownMenuItem(
                                      value: limit,
                                      child: Text('$limit tarama'),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value != null) {
                                  _changeRetentionLimit(
                                    context,
                                    ref,
                                    currentLimit:
                                        historyPreferences.maxScansPerNetwork,
                                    nextLimit: value,
                                    controller: historyController,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: const Text('Kullanım rehberi'),
                        subtitle: const Text(
                          'Tarama modlarını, Android sınırlamalarını ve '
                          'sonuçların nasıl yorumlanacağını yeniden görüntüle.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(
                          context,
                          const OnboardingScreen(reviewMode: true),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.devices_outlined),
                        title: const Text('Cihaz profillerini yönet'),
                        subtitle: const Text(
                          'Cihaz adlarını, notları ve tanıma durumlarını düzenle.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(context, const KnownDevicesScreen()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.router_outlined),
                        title: const Text('Ağ profillerini yönet'),
                        subtitle: const Text(
                          'Ağları adlandır veya bir ağın geçmişini sil.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _open(context, const NetworkProfilesScreen()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.manage_history_outlined),
                        title: const Text('Tarama geçmişini yönet'),
                        subtitle: const Text(
                          'Taramaları incele, referans seç veya verileri temizle.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(context, const HistoryScreen()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Yalnız bu cihazda saklanır'),
                    subtitle: const Text(
                      'Tema seçimi, tarama geçmişi, cihaz adları ve notlar bir '
                      'hesaba veya sunucuya gönderilmez.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, Future<void> operation) async {
    try {
      await operation;
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tema tercihi kaydedilemedi')),
        );
      }
    }
  }

  Future<void> _saveHistoryPreference(
    BuildContext context,
    WidgetRef ref,
    Future<void> operation,
  ) async {
    try {
      await operation;
      await ref.read(scanHistoryRepositoryProvider).applyRetentionLimit();
      ref.invalidate(scanHistoryProvider);
      ref.invalidate(networkScanHistoryProvider);
      ref.invalidate(networkProfilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçmiş ayarı kaydedildi')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçmiş ayarı kaydedilemedi')),
        );
      }
    }
  }

  Future<void> _changeRetentionLimit(
    BuildContext context,
    WidgetRef ref, {
    required int currentLimit,
    required int nextLimit,
    required HistoryPreferencesController controller,
  }) async {
    if (nextLimit == currentLimit) {
      return;
    }
    if (nextLimit < currentLimit) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eski taramalar temizlensin mi?'),
          content: Text(
            'Her ağda yalnız en yeni $nextLimit tarama saklanacak. Sınırı '
            'aşan eski oturumlar kalıcı olarak silinir; seçili ağ referansı '
            've cihaz profilleri korunur.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sınırı uygula'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
    }
    await _saveHistoryPreference(
      context,
      ref,
      controller.selectRetentionLimit(nextLimit),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => screen));
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${mode.label} görünüm modu',
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(mode.icon),
                  const SizedBox(width: 12),
                  Expanded(child: Text(mode.label)),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview({required this.preferences});

  final ThemePreferences preferences;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(19),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.palette_outlined, color: scheme.onPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görünüm',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${preferences.mode.label} · ${preferences.preset.label}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(preferences.preset.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPresetTile extends StatelessWidget {
  const _ColorPresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final ColorThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.label} renk teması',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: preset.previewColors
                              .map(
                                (color) => Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                      Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        size: 21,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    preset.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
