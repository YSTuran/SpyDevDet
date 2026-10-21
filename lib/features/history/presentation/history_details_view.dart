import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_formatters.dart';
import 'package:spy_dev_det/features/history/presentation/reference_comparison_card.dart';
import 'package:spy_dev_det/features/scan/domain/device_attention.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/discovery_coverage_advisor.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class HistoryDetailsView extends StatelessWidget {
  const HistoryDetailsView({
    required this.details,
    this.onSetReference,
    super.key,
  });

  final ScanHistoryDetails details;
  final VoidCallback? onSetReference;

  @override
  Widget build(BuildContext context) {
    final summary = details.summary;
    final comparison = details.referenceComparison;
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
                  formatHistoryDateTime(summary.completedAt),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.totalDeviceCount} cihaz • '
                  '${summary.newDeviceCount} uygulamada ilk kez • '
                  '${formatHistoryDuration(summary.elapsed)}',
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.scanMode.label}: ${summary.scanMode.description}',
                ),
                const SizedBox(height: 10),
                if (summary.isReference)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.bookmark),
                    title: Text('Bu tarama ağ referansı'),
                    subtitle: Text(
                      'Gelecekteki eklenen, görülmeyen ve değişen cihaz '
                      'karşılaştırmaları bu kayda göre yapılır.',
                    ),
                  )
                else if (onSetReference != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onSetReference,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Ağ referansı yap'),
                    ),
                  )
                else
                  const Text(
                    'Kısmi veya hızlı taramalar ağ referansı yapılamaz.',
                  ),
                const SizedBox(height: 12),
                ...DiscoveryMethod.values.map(
                  (method) => _HistoryMethodTile(
                    method: method,
                    result: summary.methods[method],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ReferenceComparisonCard(comparison: comparison),
        if (comparison.missingDevices.isNotEmpty) ...[
          const SizedBox(height: 12),
          _HistoryCoverageNotice(
            messages: const DiscoveryCoverageAdvisor().explain(
              methods: summary.methods,
              hasMissingDevices: true,
            ),
          ),
        ],
        const SizedBox(height: 18),
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
          const Align(
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
