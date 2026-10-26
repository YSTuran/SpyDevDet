import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_details_view.dart';
import 'package:spy_dev_det/features/history/presentation/history_formatters.dart';
import 'package:spy_dev_det/features/history/presentation/history_statistics_screen.dart';
import 'package:spy_dev_det/features/history/presentation/scan_comparison_flow.dart';
import 'package:spy_dev_det/features/history/presentation/scan_report_export_flow.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_quality.dart';

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
        actions: [
          if (networkKey == null)
            IconButton(
              tooltip: 'Ağ geçmişi istatistikleri',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const HistoryStatisticsScreen(),
                ),
              ),
              icon: const Icon(Icons.insights_outlined),
            ),
          IconButton(
            tooltip: 'İki taramayı karşılaştır',
            onPressed: () =>
                openScanComparisonFlow(context, ref, networkKey: networkKey),
            icon: const Icon(Icons.compare_arrows),
          ),
          if (networkKey == null)
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
        ],
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
    if (confirmed != true) return;
    try {
      await ref.read(scanHistoryRepositoryProvider).clearHistory();
      _invalidateHistory(ref);
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(scanHistoryRepositoryProvider).clearAllData();
      _invalidateHistory(ref);
      ref.invalidate(knownDevicesProvider);
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
                return HistoryDetailsView(
                  details: value,
                  onExport: () => exportScanReport(context, value),
                  onSetReference: value.summary.isPresenceComparable
                      ? () => _setReference(context, ref, value.summary)
                      : null,
                );
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
    if (confirmed != true || !context.mounted) return;
    await ref.read(scanHistoryRepositoryProvider).deleteSession(sessionId);
    _invalidateHistory(ref);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _setReference(
    BuildContext context,
    WidgetRef ref,
    ScanHistorySummary summary,
  ) async {
    if (summary.isReference) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu tarama zaten ağ referansı')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ağ referansı yapılsın mı?'),
        content: const Text(
          'Sonraki karşılaştırılabilir taramalarda eklenen, görülmeyen ve '
          'bilgisi değişen cihazlar bu taramaya göre belirlenecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Referans yap'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(scanHistoryRepositoryProvider)
          .setReferenceScan(summary.id);
      _invalidateHistory(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ağ referansı güncellendi')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ağ referansı güncellenemedi')),
        );
      }
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
          item.isReference
              ? Icons.bookmark
              : item.isPartial
              ? Icons.warning_amber_outlined
              : Icons.radar,
        ),
        title: Text(
          item.isReference
              ? '${formatHistoryDateTime(item.completedAt)} • Ağ referansı'
              : formatHistoryDateTime(item.completedAt),
        ),
        subtitle: Text(
          '${item.totalDeviceCount} cihaz • '
          '${item.newDeviceCount} uygulamada ilk kez • '
          '${item.missingDevices.length} görülmedi\n'
          '${item.scanMode.label} • '
          '${item.quality.level.label} • '
          '${formatHistoryDuration(item.elapsed)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
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

void _invalidateHistory(WidgetRef ref) {
  ref.invalidate(scanHistoryProvider);
  ref.invalidate(networkScanHistoryProvider);
  ref.invalidate(networkProfilesProvider);
  ref.invalidate(scanHistoryDetailsProvider);
  ref.invalidate(historyStatisticsProvider);
}
