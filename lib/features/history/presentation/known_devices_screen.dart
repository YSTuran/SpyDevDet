import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/device_timeline_screen.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/presentation/device_profile_editor.dart';

enum _DeviceProfileFilter { all, known, owned, unclassified }

extension on _DeviceProfileFilter {
  String get label => switch (this) {
    _DeviceProfileFilter.all => 'Tümü',
    _DeviceProfileFilter.known => 'Bilinen',
    _DeviceProfileFilter.owned => 'Bana ait',
    _DeviceProfileFilter.unclassified => 'Sınıflandırılmamış',
  };
}

class KnownDevicesScreen extends ConsumerStatefulWidget {
  const KnownDevicesScreen({super.key});

  @override
  ConsumerState<KnownDevicesScreen> createState() => _KnownDevicesScreenState();
}

class _KnownDevicesScreenState extends ConsumerState<KnownDevicesScreen> {
  final _searchController = TextEditingController();
  var _filter = _DeviceProfileFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(knownDevicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cihazlar')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: devices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(knownDevicesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Cihazları tekrar yükle'),
                ),
              ),
              data: (items) {
                final visible = _applyFilter(items);
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(knownDevicesProvider.future),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Cihazlarda ara',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Aramayı temizle',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_DeviceProfileFilter>(
                        initialValue: _filter,
                        decoration: const InputDecoration(
                          labelText: 'Filtre',
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: _DeviceProfileFilter.values
                            .map(
                              (filter) => DropdownMenuItem(
                                value: filter,
                                child: Text(filter.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _filter = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kayıtlı cihaz profilleri (${visible.length}/${items.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bu liste geçmiş temizlense bile korunan cihaz adlarını, '
                        'notları ve tanıma durumlarını gösterir.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        const _EmptyDevices()
                      else if (visible.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Arama ve filtrelerle eşleşen cihaz yok.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...visible.map(
                          (device) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _KnownDeviceCard(
                              device: device,
                              onViewHistory: () => _viewHistory(device),
                              onEdit: () => _edit(device),
                              onForget: () => _forget(device),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<KnownDeviceSummary> _applyFilter(List<KnownDeviceSummary> devices) {
    final query = _searchController.text.trim().toLowerCase();
    return devices
        .where((device) {
          final matchesFilter = switch (_filter) {
            _DeviceProfileFilter.all => true,
            _DeviceProfileFilter.known => device.isKnown,
            _DeviceProfileFilter.owned => device.isOwned,
            _DeviceProfileFilter.unclassified => !device.isKnown,
          };
          if (!matchesFilter) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return [
            device.effectiveDisplayName,
            device.displayName,
            device.lastIpAddress,
            device.lastMacAddress,
            device.vendor,
            device.note,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
        })
        .toList(growable: false);
  }

  Future<void> _edit(KnownDeviceSummary device) async {
    final edit = await showDeviceProfileEditor(
      context,
      isKnown: device.isKnown,
      isOwned: device.isOwned,
      customName: device.customName,
      note: device.note,
      categoryOverride: device.categoryOverride,
    );
    if (edit == null || !mounted) {
      return;
    }
    try {
      await ref
          .read(scanHistoryRepositoryProvider)
          .updateDeviceProfile(
            stableKey: device.stableKey,
            isKnown: edit.isKnown,
            customName: edit.customName,
            note: edit.note,
            isOwned: edit.isOwned,
            categoryOverride: edit.categoryOverride,
            clearCategoryOverride: edit.categoryOverride == null,
          );
      ref.invalidate(knownDevicesProvider);
      ref.invalidate(scanHistoryProvider);
      ref.invalidate(scanHistoryDetailsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihaz profili güncellendi')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihaz profili güncellenemedi')),
        );
      }
    }
  }

  void _viewHistory(KnownDeviceSummary device) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DeviceTimelineScreen(
          stableKey: device.stableKey,
          initialTitle: device.effectiveDisplayName,
        ),
      ),
    );
  }

  Future<void> _forget(KnownDeviceSummary device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihaz profili unutulsun mu?'),
        content: Text(
          '${device.effectiveDisplayName} için saklanan ad, not, sahiplik ve '
          'kimlik eşleştirmeleri silinir. Eski tarama kayıtları korunur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Profili unut'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(scanHistoryRepositoryProvider)
          .forgetDevice(device.stableKey);
      ref.invalidate(knownDevicesProvider);
      ref.invalidate(scanHistoryProvider);
      ref.invalidate(scanHistoryDetailsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cihaz profili unutuldu')));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihaz profili silinemedi')),
        );
      }
    }
  }
}

class _KnownDeviceCard extends StatelessWidget {
  const _KnownDeviceCard({
    required this.device,
    required this.onViewHistory,
    required this.onEdit,
    required this.onForget,
  });

  final KnownDeviceSummary device;
  final VoidCallback onViewHistory;
  final VoidCallback onEdit;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(device.isOwned ? Icons.home_outlined : Icons.devices),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    device.effectiveDisplayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<_DeviceAction>(
                  tooltip: 'Cihaz seçenekleri',
                  onSelected: (action) => switch (action) {
                    _DeviceAction.history => onViewHistory(),
                    _DeviceAction.edit => onEdit(),
                    _DeviceAction.forget => onForget(),
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _DeviceAction.history,
                      child: Text('Cihaz geçmişini görüntüle'),
                    ),
                    PopupMenuItem(
                      value: _DeviceAction.edit,
                      child: Text('Profili düzenle'),
                    ),
                    PopupMenuItem(
                      value: _DeviceAction.forget,
                      child: Text('Profili unut'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Son IP: ${device.lastIpAddress}'),
            if (device.lastMacAddress != null)
              Text('MAC: ${device.lastMacAddress}'),
            if (device.vendor != null) Text('Üretici: ${device.vendor}'),
            Text('Son görülme: ${_formatDateTime(device.lastSeenAt)}'),
            if (device.note?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text('Not: ${device.note}'),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(device.isKnown ? 'Bilinen' : 'Tanımlanmadı')),
                if (device.isOwned) const Chip(label: Text('Bana ait')),
                if (device.categoryOverride != null)
                  Chip(label: Text(device.categoryOverride!.label)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _DeviceAction { history, edit, forget }

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Henüz kayıtlı cihaz profili yok. Tamamlanan ilk taramadan sonra '
        'gözlemlenen cihazlar burada görünecek.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
