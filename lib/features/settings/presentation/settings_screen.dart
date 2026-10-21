import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/presentation/history_screen.dart';
import 'package:spy_dev_det/features/history/presentation/known_devices_screen.dart';
import 'package:spy_dev_det/features/history/presentation/network_profiles_screen.dart';
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
                          builder: (context, constraints) => SizedBox(
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
                          ),
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
                          'Renkler Material 3 tarafından okunabilir yüzey ve '
                          'metin renklerine dönüştürülür.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = constraints.maxWidth >= 620
                                ? (constraints.maxWidth - 24) / 3
                                : constraints.maxWidth >= 400
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => screen));
  }
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview({required this.preferences});

  final ThemePreferences preferences;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.palette_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preferences.mode.label} + ${preferences.preset.label}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
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
    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.label} renk teması',
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: preset.seedColor, radius: 15),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        preset.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
