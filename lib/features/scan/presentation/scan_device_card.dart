part of 'scan_screen.dart';

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onManage});

  final DeviceObservation device;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final attention = const DeviceAttentionEvaluator().evaluate(device);
    return Card(
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.devices),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      device.effectiveDisplayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Text(device.ipAddress),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: Icon(
                      _categoryIcon(device.effectiveCategory),
                      size: 18,
                    ),
                    label: Text(device.effectiveCategory.label),
                  ),
                  if (device.categoryOverride != null)
                    const Chip(
                      avatar: Icon(Icons.edit_outlined, size: 18),
                      label: Text('Kullanıcı düzeltmesi'),
                    ),
                  if (device.isOwned)
                    const Chip(
                      avatar: Icon(Icons.home_outlined, size: 18),
                      label: Text('Bana ait'),
                    ),
                  Chip(label: Text(device.confidence.label)),
                  Chip(
                    avatar: Icon(
                      attention.level == AttentionLevel.review
                          ? Icons.manage_search_outlined
                          : attention.level == AttentionLevel.informational
                          ? Icons.info_outline
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(attention.level.label),
                  ),
                  if (device.familiarity != DeviceFamiliarity.unclassified)
                    Chip(
                      avatar: Icon(
                        device.isKnown
                            ? Icons.verified_user_outlined
                            : device.familiarity == DeviceFamiliarity.newDevice
                            ? Icons.fiber_new_outlined
                            : Icons.history,
                        size: 18,
                      ),
                      label: Text(device.familiarity.label),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                device.macStatus.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (device.services.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: device.services
                      .map((service) => Chip(label: Text(service)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final attention = const DeviceAttentionEvaluator().evaluate(device);
    final serviceInsights = const ServiceCatalog().inspect(device);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.effectiveDisplayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'IP adresi', value: device.ipAddress),
              _DetailRow(
                label: 'Bulunma yöntemi',
                value: device.discoveryMethod,
              ),
              _DetailRow(
                label: 'Cihaz türü',
                value:
                    '${device.effectiveCategory.label} • '
                    '${device.confidence.label}',
              ),
              if (device.categoryOverride != null)
                _DetailRow(
                  label: 'Otomatik tahmin',
                  value:
                      '${device.category.label} (kullanıcı tarafından '
                      'düzeltildi)',
                ),
              _DetailRow(
                label: 'İnceleme durumu',
                value:
                    '${attention.level.label} • ${attention.score} puan\n'
                    '${attention.factors.map((factor) => '+${factor.points}: '
                        '${factor.description}').join('\n')}',
              ),
              _DetailRow(
                label: 'Gözlemlenen servisler',
                value: device.services.isEmpty
                    ? 'Bilinmiyor'
                    : device.services.join(', '),
              ),
              if (serviceInsights.isNotEmpty)
                _DetailRow(
                  label: 'Servis yorumları',
                  value: serviceInsights
                      .map(
                        (insight) =>
                            '${insight.title}: ${insight.explanation}'
                            '${insight.caution == null ? '' : ' ${insight.caution}'}',
                      )
                      .join('\n\n'),
                ),
              _DetailRow(label: 'MAC durumu', value: device.macStatus.label),
              _DetailRow(
                label: 'MAC adresi',
                value: device.macAddress ?? 'Bilinmiyor',
              ),
              _DetailRow(
                label: 'Üretici',
                value: device.hasKnownVendor ? device.vendor! : 'Bilinmiyor',
              ),
              if (device.familiarity != DeviceFamiliarity.unclassified)
                _DetailRow(
                  label: 'Tanıma durumu',
                  value: device.isOwned
                      ? '${device.familiarity.label} • Bana/evime ait'
                      : device.familiarity.label,
                ),
              if (device.note?.trim().isNotEmpty == true)
                _DetailRow(label: 'Not', value: device.note!),
              _DetailRow(
                label: 'Kanıtlar',
                value: device.evidence.isEmpty
                    ? 'Sınıflandırma kanıtı bulunmuyor'
                    : device.evidence
                          .map(
                            (item) =>
                                '${item.source.label}: ${item.description}',
                          )
                          .join('\n'),
              ),
              if (device.category == DeviceCategory.cameraCandidate ||
                  device.effectiveCategory == DeviceCategory.cameraCandidate)
                Text(
                  'Kamera adayı etiketi yalnızca ağ servislerine dayanır; '
                  'cihazın gizli veya kötü amaçlı olduğunu kanıtlamaz.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (device.stableKey != null && !_isLocalDevice(device)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(context);
                      onManage();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Cihaz profilini düzenle'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(DeviceCategory category) => switch (category) {
    DeviceCategory.router => Icons.router_outlined,
    DeviceCategory.cameraCandidate => Icons.videocam_outlined,
    DeviceCategory.printer => Icons.print_outlined,
    DeviceCategory.mediaDevice => Icons.tv_outlined,
    DeviceCategory.computerOrPhone => Icons.devices_outlined,
    DeviceCategory.unknown => Icons.help_outline,
  };

  bool _isLocalDevice(DeviceObservation value) => value.evidence.any(
    (item) =>
        item.source == DeviceEvidenceSource.network &&
        item.description == 'Taramanın çalıştığı cihaz',
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
