part of 'scan_screen.dart';

class _CoverageNotice extends StatelessWidget {
  const _CoverageNotice({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bazı cihazlar neden görünmeyebilir?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
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

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.devices});

  final List<DeviceObservation> devices;

  @override
  Widget build(BuildContext context) {
    const evaluator = DeviceAttentionEvaluator();
    final newCount = devices
        .where((device) => device.familiarity == DeviceFamiliarity.newDevice)
        .length;
    final knownCount = devices.where((device) => device.isKnown).length;
    final cameraCount = devices
        .where(
          (device) =>
              device.effectiveCategory == DeviceCategory.cameraCandidate,
        )
        .length;
    final reviewCount = devices
        .where(
          (device) => evaluator.evaluate(device).level == AttentionLevel.review,
        )
        .length;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sonuç özeti', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('$newCount uygulamada ilk kez')),
                Chip(label: Text('$knownCount bilinen')),
                Chip(label: Text('$cameraCount kamera adayı')),
                Chip(label: Text('$reviewCount incelenmesi önerilen')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'İnceleme durumu yalnız gözlemlenen ağ kanıtlarını özetler; '
              'bir cihazın gizli veya kötü amaçlı olduğunu kanıtlamaz.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.security_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Yalnızca sahibi olduğun veya tarama izni aldığın yerel '
                'ağlarda kullan. Tarama en fazla 254 özel IPv4 adresiyle, '
                'sekiz yaygın TCP portuyla ve yerel servis duyurularıyla sınırlıdır.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final network = state.network;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarama durumu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Semantics(
              container: true,
              liveRegion: true,
              label: 'Tarama durumu: ${state.statusMessage}',
              excludeSemantics: true,
              child: Text(state.statusMessage),
            ),
            if (network != null) ...[
              const SizedBox(height: 12),
              _StatusLine(label: 'Yerel IP', value: network.cidr),
              _StatusLine(
                label: 'Bağlantı',
                value: network.isWifi
                    ? 'Wi-Fi (${network.interfaceName})'
                    : 'Ethernet (${network.interfaceName})',
              ),
              _StatusLine(
                label: 'Ağ geçidi',
                value: network.gatewayIpv4 ?? 'Bilinmiyor',
              ),
              if (state.scanRange != null)
                _StatusLine(label: 'Tarama aralığı', value: state.scanRange!),
              if (state.rangeTruncated)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Büyük ağ güvenlik ve performans için 254 hedefle sınırlandı.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (state.elapsed != null)
                _StatusLine(
                  label: 'Süre',
                  value: '${state.elapsed!.inMilliseconds / 1000} sn',
                ),
            ],
            if (state.report case final report?) ...[
              const SizedBox(height: 10),
              const Divider(),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: Text(
                  'Keşif yöntemleri',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                children: [
                  ...DiscoveryMethod.values.map(
                    (method) => _MethodResultRow(
                      result:
                          report.methods[method] ??
                          DiscoveryMethodResult.waiting(method),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const ScanDiagnosticsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.monitor_heart_outlined),
                      label: const Text('Tanılama ayrıntıları'),
                    ),
                  ),
                  if (report.completedAt != null && report.isPartial)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Tarama kısmi tamamlandı; kullanılamayan yöntemler olabilir.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label: 'Tarama ilerlemesi',
              value: 'Yüzde ${(state.progress * 100).round()}',
              excludeSemantics: true,
              child: LinearProgressIndicator(
                value: state.phase == ScanPhase.preparing
                    ? null
                    : state.progress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodResultRow extends StatelessWidget {
  const _MethodResultRow({required this.result});

  final DiscoveryMethodResult result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.phase) {
      DiscoveryMethodPhase.completed => Colors.green,
      DiscoveryMethodPhase.platformRestricted => Colors.orange,
      DiscoveryMethodPhase.unavailable ||
      DiscoveryMethodPhase.failed => Theme.of(context).colorScheme.error,
      DiscoveryMethodPhase.running => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.phase == DiscoveryMethodPhase.running
                ? Icons.sync
                : result.phase == DiscoveryMethodPhase.completed
                ? Icons.check_circle_outline
                : result.phase == DiscoveryMethodPhase.platformRestricted
                ? Icons.info_outline
                : result.phase == DiscoveryMethodPhase.skipped
                ? Icons.skip_next_outlined
                : result.isProblem
                ? Icons.warning_amber_outlined
                : Icons.schedule,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${result.method.label}: ${result.phase.label}'
              '${result.phase == DiscoveryMethodPhase.completed ? ' • ${result.deviceCount}' : ''}'
              '${result.userMessage == null ? '' : '\n${result.userMessage}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices({required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final message = switch (state.phase) {
      ScanPhase.scanning || ScanPhase.preparing =>
        'Tarama sürüyor. Yanıt veren cihazlar burada görünecek.',
      ScanPhase.saving => 'Tarama sonucu yerel geçmişe kaydediliyor.',
      ScanPhase.completed =>
        'Kullanılan keşif yöntemlerinde cihaz gözlemlenmedi. Bu sonuç ağda '
            'başka cihaz olmadığı anlamına gelmez.',
      ScanPhase.failed =>
        'Tarama başlatılamadı. Yukarıdaki açıklamayı kontrol et.',
      _ => 'Henüz gözlemlenen cihaz yok. Yerel ağ taramasını başlatabilirsin.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.devices_other,
              size: 42,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
