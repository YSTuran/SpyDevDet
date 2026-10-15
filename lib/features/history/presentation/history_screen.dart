import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarama geçmişi'),
        actions: [
          IconButton(
            tooltip: 'Geçmişi temizle',
            onPressed: () => _clearHistory(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _HistoryError(
                onRetry: () => ref.invalidate(scanHistoryProvider),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(scanHistoryProvider.future),
                child: items.isEmpty
                    ? const _EmptyHistory()
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _HistoryCard(
                          item: items[index],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => HistoryDetailsScreen(
                                sessionId: items[index].id,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarama geçmişi silinsin mi?'),
        content: const Text(
          'Tarama oturumları silinir. Bilinen cihaz adları ve notları korunur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Geçmişi sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(scanHistoryRepositoryProvider).clearHistory();
    ref.invalidate(scanHistoryProvider);
  }
}

class HistoryDetailsScreen extends ConsumerWidget {
  const HistoryDetailsScreen({required this.sessionId, super.key});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(scanHistoryDetailsProvider(sessionId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarama ayrıntıları'),
        actions: [
          IconButton(
            tooltip: 'Bu taramayı sil',
            onPressed: () => _deleteSession(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: details.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _HistoryError(
                onRetry: () =>
                    ref.invalidate(scanHistoryDetailsProvider(sessionId)),
              ),
              data: (value) {
                if (value == null) {
                  return const Center(child: Text('Tarama kaydı bulunamadı.'));
                }
                return _HistoryDetails(details: value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSession(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarama kaydı silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(scanHistoryRepositoryProvider).deleteSession(sessionId);
    ref.invalidate(scanHistoryProvider);
    ref.invalidate(scanHistoryDetailsProvider(sessionId));
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onTap});

  final ScanHistorySummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          item.isPartial ? Icons.warning_amber_outlined : Icons.radar,
        ),
        title: Text(_formatDateTime(item.completedAt)),
        subtitle: Text(
          '${item.totalDeviceCount} cihaz • ${item.newDeviceCount} yeni • '
          '${item.missingDevices.length} görülmedi\n'
          '${item.isPartial ? 'Kısmi tarama' : 'Tam tarama'} • '
          '${_formatDuration(item.elapsed)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _HistoryDetails extends StatelessWidget {
  const _HistoryDetails({required this.details});

  final ScanHistoryDetails details;

  @override
  Widget build(BuildContext context) {
    final summary = details.summary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(summary.completedAt),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.totalDeviceCount} cihaz • '
                  '${summary.newDeviceCount} yeni • '
                  '${summary.missingDevices.length} görülmedi • '
                  '${_formatDuration(summary.elapsed)}',
                ),
                const SizedBox(height: 12),
                ...DiscoveryMethod.values.map((method) {
                  final result = summary.methods[method];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${method.label}: '
                      '${result?.phase.label ?? 'Kayıt yok'}'
                      '${result == null ? '' : ' • ${result.deviceCount}'}',
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (summary.missingDevices.isNotEmpty) ...[
          Text(
            'Bu taramada görülmeyen cihazlar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...summary.missingDevices.map(
            (device) => Card(
              child: ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text(device.displayName),
                subtitle: Text('Son IP: ${device.lastIpAddress}'),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          'Bu taramada gözlemlenen cihazlar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (details.devices.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Bu taramada cihaz gözlemlenmedi.'),
            ),
          )
        else
          ...details.devices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    device.isKnown
                        ? Icons.verified_user_outlined
                        : device.familiarity == DeviceFamiliarity.newDevice
                        ? Icons.fiber_new_outlined
                        : Icons.devices_outlined,
                  ),
                  title: Text(device.effectiveDisplayName),
                  subtitle: Text(
                    '${device.ipAddress}\n${device.familiarity.label}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.history, size: 48),
        SizedBox(height: 12),
        Text(
          'Henüz tamamlanmış bir tarama kaydı yok.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tarama geçmişi okunamadı.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

String _formatDuration(Duration value) {
  final seconds = value.inMilliseconds / 1000;
  return '${seconds.toStringAsFixed(1)} sn';
}
