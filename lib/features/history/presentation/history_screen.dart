import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/scan/domain/device_attention.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/discovery_coverage_advisor.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({this.networkKey, this.title, super.key});

  final String? networkKey;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = networkKey == null
        ? ref.watch(scanHistoryProvider)
        : ref.watch(networkScanHistoryProvider(networkKey!));
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Tarama geçmişi'),
        actions: networkKey == null
            ? [
                PopupMenuButton<_HistoryAction>(
                  tooltip: 'Geçmiş seçenekleri',
                  onSelected: (action) {
                    switch (action) {
                      case _HistoryAction.clearHistory:
                        _clearHistory(context, ref);
                      case _HistoryAction.clearAllData:
                        _clearAllData(context, ref);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _HistoryAction.clearHistory,
                      child: Text('Yalnız tarama geçmişini sil'),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.clearAllData,
                      child: Text('Tüm tarama verilerini sil'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _HistoryError(
                onRetry: () => networkKey == null
                    ? ref.invalidate(scanHistoryProvider)
                    : ref.invalidate(networkScanHistoryProvider(networkKey!)),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => networkKey == null
                    ? ref.refresh(scanHistoryProvider.future)
                    : ref.refresh(
                        networkScanHistoryProvider(networkKey!).future,
                      ),
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
    try {
      await ref.read(scanHistoryRepositoryProvider).clearHistory();
      ref.invalidate(scanHistoryProvider);
      ref.invalidate(networkScanHistoryProvider);
      ref.invalidate(networkProfilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarama geçmişi silindi')));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarama geçmişi silinemedi')),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm tarama verileri silinsin mi?'),
        content: const Text(
          'Tarama geçmişi, bilinen cihaz işaretleri, özel adlar ve notlar '
          'kalıcı olarak silinir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tümünü sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(scanHistoryRepositoryProvider).clearAllData();
      ref.invalidate(scanHistoryProvider);
      ref.invalidate(networkScanHistoryProvider);
      ref.invalidate(networkProfilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm tarama verileri silindi')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarama verileri silinemedi')),
        );
      }
    }
  }
}

enum _HistoryAction { clearHistory, clearAllData }

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
    ref.invalidate(networkScanHistoryProvider);
    ref.invalidate(networkProfilesProvider);
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
          '${item.scanMode.label} • '
          '${item.isPartial ? 'Kısmi sonuç' : 'Planlandığı gibi tamamlandı'} • '
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
                const SizedBox(height: 4),
                Text(
                  '${summary.scanMode.label}: ${summary.scanMode.description}',
                ),
                const SizedBox(height: 12),
                ...DiscoveryMethod.values.map((method) {
                  final result = summary.methods[method];
                  return _HistoryMethodTile(method: method, result: result);
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (summary.missingDevices.isNotEmpty) ...[
          _HistoryCoverageNotice(
            messages: const DiscoveryCoverageAdvisor().explain(
              methods: summary.methods,
              hasMissingDevices: true,
            ),
          ),
          const SizedBox(height: 18),
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
              child: _HistoryDeviceCard(device: device),
            ),
          ),
      ],
    );
  }
}

class _HistoryDeviceCard extends StatelessWidget {
  const _HistoryDeviceCard({required this.device});

  final DeviceObservation device;

  @override
  Widget build(BuildContext context) {
    final attention = const DeviceAttentionEvaluator().evaluate(device);
    return Card(
      child: ExpansionTile(
        leading: Icon(
          device.isKnown
              ? Icons.verified_user_outlined
              : device.familiarity == DeviceFamiliarity.newDevice
              ? Icons.fiber_new_outlined
              : Icons.devices_outlined,
        ),
        title: Text(device.effectiveDisplayName),
        subtitle: Text(
          '${device.ipAddress} • ${device.effectiveCategory.label}\n'
          '${device.familiarity.label} • ${attention.level.label}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _HistoryDetailLine(
            label: 'İnceleme puanı',
            value: '${attention.score}',
          ),
          ...attention.factors.map(
            (factor) => _HistoryDetailLine(
              label: '+${factor.points}',
              value: factor.description,
            ),
          ),
          if (device.categoryOverride != null)
            _HistoryDetailLine(
              label: 'Tür düzeltmesi',
              value:
                  '${device.category.label} → '
                  '${device.categoryOverride!.label}',
            ),
          if (device.isOwned)
            const _HistoryDetailLine(
              label: 'Sahiplik',
              value: 'Bana/evime ait olarak işaretlendi',
            ),
          _HistoryDetailLine(
            label: 'Servisler',
            value: device.services.isEmpty
                ? 'Gözlemlenmedi'
                : device.services.join(', '),
          ),
          _HistoryDetailLine(
            label: 'MAC',
            value: device.macAddress ?? device.macStatus.label,
          ),
          if (device.evidence.isNotEmpty)
            _HistoryDetailLine(
              label: 'Kanıtlar',
              value: device.evidence
                  .map((item) => '${item.source.label}: ${item.description}')
                  .join('\n'),
            ),
        ],
      ),
    );
  }
}

class _HistoryDetailLine extends StatelessWidget {
  const _HistoryDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _HistoryCoverageNotice extends StatelessWidget {
  const _HistoryCoverageNotice({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bir cihaz neden görülmemiş olabilir?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...messages.map(
              (message) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMethodTile extends StatelessWidget {
  const _HistoryMethodTile({required this.method, required this.result});

  final DiscoveryMethod method;
  final DiscoveryMethodResult? result;

  @override
  Widget build(BuildContext context) {
    final current = result;
    if (current == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(method.label),
        trailing: const Text('Kayıt yok'),
      );
    }
    final metrics = current.metrics;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
      dense: true,
      title: Text(method.label),
      subtitle: Text(
        '${current.phase.label} • ${current.deviceCount} cihaz • '
        '${current.elapsed.inMilliseconds} ms',
      ),
      children: [
        if (!metrics.hasValues)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Bu kayıtta ayrıntılı tanılama sayacı yok.'),
          ),
        if (metrics.hasValues) ...[
          if (metrics.attemptedTargets > 0)
            _HistoryMetricLine(
              'Kontrol edilen hedef',
              metrics.attemptedTargets,
            ),
          _HistoryMetricLine('Gönderilen istek', metrics.sentRequests),
          _HistoryMetricLine('Alınan yanıt', metrics.receivedResponses),
          _HistoryMetricLine('Kabul edilen yanıt', metrics.acceptedResponses),
          _HistoryMetricLine('Yok sayılan yanıt', metrics.ignoredResponses),
          if (metrics.timeoutCount > 0)
            _HistoryMetricLine('Zaman aşımı', metrics.timeoutCount),
          if (metrics.multicastLockAcquired case final acquired?)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Multicast erişimi: ${acquired ? 'Alındı' : 'Alınamadı'}',
              ),
            ),
          if (metrics.detail case final detail?)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Teknik açıklama: $detail'),
            ),
        ],
        if (current.userMessage case final message?)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _HistoryMetricLine extends StatelessWidget {
  const _HistoryMetricLine(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text('$label: $value'),
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
