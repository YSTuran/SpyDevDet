import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_screen.dart';
import 'package:spy_dev_det/features/history/presentation/history_statistics_screen.dart';

class NetworkProfilesScreen extends ConsumerWidget {
  const NetworkProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(networkProfilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ağ profilleri')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: profiles.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(networkProfilesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ağ profillerini tekrar yükle'),
                ),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(networkProfilesProvider.future),
                child: items.isEmpty
                    ? const _EmptyNetworkProfiles()
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final profile = items[index];
                          return _NetworkProfileCard(
                            profile: profile,
                            onRename: () => _rename(context, ref, profile),
                            onDelete: () => _delete(context, ref, profile),
                            onStatistics: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => HistoryStatisticsScreen(
                                  initialNetworkKey: profile.networkKey,
                                ),
                              ),
                            ),
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => HistoryScreen(
                                  networkKey: profile.networkKey,
                                  title: profile.displayName,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    NetworkProfileSummary profile,
  ) async {
    final controller = TextEditingController(text: profile.customName);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ağ profilini adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Ağ adı',
            hintText: 'Örneğin: Ev ağı',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (save != true || !context.mounted) {
      controller.dispose();
      return;
    }
    try {
      await ref
          .read(scanHistoryRepositoryProvider)
          .renameNetworkProfile(
            networkKey: profile.networkKey,
            customName: controller.text,
          );
      ref.invalidate(networkProfilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ağ profili güncellendi')));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ağ profili güncellenemedi')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    NetworkProfileSummary profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ağ profili silinsin mi?'),
        content: Text(
          '${profile.displayName} için saklanan bütün tarama oturumları ve '
          'ağ kimliği silinir. Cihaz adları ve notları korunur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ağı sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(scanHistoryRepositoryProvider)
          .deleteNetworkData(profile.networkKey);
      ref.invalidate(networkProfilesProvider);
      ref.invalidate(scanHistoryProvider);
      ref.invalidate(networkScanHistoryProvider);
      ref.invalidate(knownDevicesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ağ profili ve geçmişi silindi')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ağ profili silinemedi')));
      }
    }
  }
}

class _NetworkProfileCard extends StatelessWidget {
  const _NetworkProfileCard({
    required this.profile,
    required this.onRename,
    required this.onDelete,
    required this.onStatistics,
    required this.onOpen,
  });

  final NetworkProfileSummary profile;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onStatistics;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const Icon(Icons.router_outlined),
        title: Text(profile.displayName),
        subtitle: Text(
          '${_safeNetworkLabel(profile.networkKey)} • '
          'kimlik ${profile.hasStrongIdentity ? 'güçlü' : 'sınırlı'}\n'
          '${profile.scanCount} tarama • son taramada '
          '${profile.lastDeviceCount} cihaz\n'
          'Son görülme: ${_formatDateTime(profile.lastSeenAt)}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_NetworkAction>(
          tooltip: 'Ağ seçenekleri',
          onSelected: (action) => switch (action) {
            _NetworkAction.rename => onRename(),
            _NetworkAction.statistics => onStatistics(),
            _NetworkAction.delete => onDelete(),
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _NetworkAction.statistics,
              child: Text('İstatistikleri göster'),
            ),
            PopupMenuItem(
              value: _NetworkAction.rename,
              child: Text('Ağı adlandır'),
            ),
            PopupMenuItem(
              value: _NetworkAction.delete,
              child: Text('Ağı ve geçmişini sil'),
            ),
          ],
        ),
      ),
    );
  }

  String _safeNetworkLabel(String key) {
    final base = key
        .split('|gateway-mac:')
        .first
        .split('|gateway-service:')
        .first;
    return base.replaceFirst('|gateway:', ' • ağ geçidi ');
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

enum _NetworkAction { rename, statistics, delete }

class _EmptyNetworkProfiles extends StatelessWidget {
  const _EmptyNetworkProfiles();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.router_outlined, size: 48),
        SizedBox(height: 12),
        Text(
          'Henüz kayıtlı bir ağ profili yok. İlk tamamlanan taramadan sonra '
          'ağ burada görünecek.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
