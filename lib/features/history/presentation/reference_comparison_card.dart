import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/history/domain/reference_scan_comparison.dart';
import 'package:spy_dev_det/features/history/presentation/history_formatters.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';

class ReferenceComparisonCard extends StatelessWidget {
  const ReferenceComparisonCard({required this.comparison, super.key});

  final ReferenceScanComparison comparison;

  @override
  Widget build(BuildContext context) => switch (comparison.state) {
    ReferenceComparisonState.currentIsReference => _messageCard(
      context,
      icon: Icons.bookmark,
      title: 'Bu tarama ağ referansı',
      message:
          'Daha sonra tamamlanan karşılaştırılabilir taramalar bu kayıtla '
          'kıyaslanır.',
    ),
    ReferenceComparisonState.notComparable => _messageCard(
      context,
      icon: Icons.compare_arrows_outlined,
      title: 'Karşılaştırma yapılmadı',
      message:
          'Hızlı veya kısmi taramalar, yanlış değişiklik uyarısı üretmemek '
          'için referansla karşılaştırılmaz.',
    ),
    ReferenceComparisonState.noBaseline => _messageCard(
      context,
      icon: Icons.bookmark_add_outlined,
      title: 'Karşılaştırma temeli yok',
      message:
          'Bu ağda daha eski karşılaştırılabilir bir tarama bulunmuyor. '
          'Ayrıntılı bir taramayı referans olarak seçebilirsin.',
    ),
    ReferenceComparisonState.available => _availableComparison(context),
  };

  Widget _availableComparison(BuildContext context) {
    final baselineTime = comparison.baselineCompletedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tarama karşılaştırması',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              baselineTime == null
                  ? 'Karşılaştırma temeli'
                  : '${switch (comparison.baselineKind) {
                          ComparisonBaselineKind.explicitReference => 'Seçili ağ referansı',
                          ComparisonBaselineKind.previousComparable => 'Önceki uygun tarama',
                          ComparisonBaselineKind.userSelected => 'Kullanıcının seçtiği temel tarama',
                        }}: '
                        '${formatHistoryDateTime(baselineTime)}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text('${comparison.addedDevices.length} eklendi'),
                ),
                Chip(
                  avatar: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: Text('${comparison.missingDevices.length} görülmedi'),
                ),
                Chip(
                  avatar: const Icon(Icons.change_circle_outlined, size: 18),
                  label: Text('${comparison.changedDevices.length} değişti'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!comparison.hasChanges)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(switch (comparison.baselineKind) {
                  ComparisonBaselineKind.explicitReference =>
                    'Referansa göre değişiklik gözlemlenmedi',
                  ComparisonBaselineKind.previousComparable =>
                    'Önceki uygun taramaya göre değişiklik gözlemlenmedi',
                  ComparisonBaselineKind.userSelected =>
                    'Seçilen temel taramaya göre değişiklik gözlemlenmedi',
                }),
              ),
            if (comparison.addedDevices.isNotEmpty)
              _DeviceChangeGroup(
                title: switch (comparison.baselineKind) {
                  ComparisonBaselineKind.explicitReference =>
                    'Referanstan sonra eklenen cihazlar',
                  ComparisonBaselineKind.previousComparable =>
                    'Önceki uygun taramadan sonra eklenen cihazlar',
                  ComparisonBaselineKind.userSelected =>
                    'Seçilen taramadan sonra eklenen cihazlar',
                },
                icon: Icons.add_circle_outline,
                devices: comparison.addedDevices,
              ),
            if (comparison.missingDevices.isNotEmpty)
              _DeviceChangeGroup(
                title: 'Bu taramada görülmeyen cihazlar',
                icon: Icons.visibility_off_outlined,
                devices: comparison.missingDevices,
              ),
            if (comparison.changedDevices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Bilgisi değişen cihazlar',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...comparison.changedDevices.map(_ChangedDeviceTile.new),
            ],
          ],
        ),
      ),
    );
  }

  Widget _messageCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}

class _DeviceChangeGroup extends StatelessWidget {
  const _DeviceChangeGroup({
    required this.title,
    required this.icon,
    required this.devices,
  });

  final String title;
  final IconData icon;
  final List<ComparedDeviceSummary> devices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        ...devices.map(
          (device) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(icon),
            title: Text(device.displayName),
            subtitle: Text(
              '${device.ipAddress} • ${device.category.label}'
              '${device.vendor == null ? '' : ' • ${device.vendor}'}',
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangedDeviceTile extends StatelessWidget {
  const _ChangedDeviceTile(this.change);

  final ReferenceDeviceChange change;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
      leading: Icon(
        change.identityQualityDegraded
            ? Icons.warning_amber_outlined
            : Icons.change_circle_outlined,
      ),
      title: Text(change.device.displayName),
      subtitle: Text(change.device.ipAddress),
      children: [
        if (change.ipChanged)
          _ChangeLine(
            label: 'IP adresi',
            value: '${change.previousIpAddress} → ${change.currentIpAddress}',
          ),
        if (change.addedServices.isNotEmpty)
          _ChangeLine(
            label: 'Yeni servisler',
            value: change.addedServices.join(', '),
          ),
        if (change.removedServices.isNotEmpty)
          _ChangeLine(
            label: 'Görülmeyen servisler',
            value: change.removedServices.join(', '),
          ),
        if (change.vendorChanged)
          _ChangeLine(
            label: 'Üretici',
            value:
                '${change.previousVendor ?? 'Bilinmiyor'} → '
                '${change.currentVendor ?? 'Bilinmiyor'}',
          ),
        if (change.categoryChanged)
          _ChangeLine(
            label: 'Otomatik tür',
            value:
                '${change.previousCategory.label} → '
                '${change.currentCategory.label}',
          ),
        if (change.confidenceChanged)
          _ChangeLine(
            label: 'Sınıflandırma güveni',
            value:
                '${change.previousConfidence.label} → '
                '${change.currentConfidence.label}',
          ),
        if (change.identityQualityChanged)
          _ChangeLine(
            label: 'Kimlik kanıtı',
            value:
                '${change.previousIdentityQuality.label} → '
                '${change.currentIdentityQuality.label}',
          ),
      ],
    );
  }
}

class _ChangeLine extends StatelessWidget {
  const _ChangeLine({required this.label, required this.value});

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
            width: 136,
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
