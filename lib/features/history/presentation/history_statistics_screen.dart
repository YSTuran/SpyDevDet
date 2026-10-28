import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/history/application/history_providers.dart';
import 'package:spy_dev_det/features/history/domain/network_history_statistics.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/presentation/history_formatters.dart';

class HistoryStatisticsScreen extends ConsumerStatefulWidget {
  const HistoryStatisticsScreen({this.initialNetworkKey, super.key});

  final String? initialNetworkKey;

  @override
  ConsumerState<HistoryStatisticsScreen> createState() =>
      _HistoryStatisticsScreenState();
}

class _HistoryStatisticsScreenState
    extends ConsumerState<HistoryStatisticsScreen> {
  static const _allNetworksValue = '__all_networks__';
  late String? _selectedNetworkKey = widget.initialNetworkKey;

  @override
  Widget build(BuildContext context) {
    final statistics = ref.watch(
      historyStatisticsProvider(_selectedNetworkKey),
    );
    final profiles = ref.watch(networkProfilesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ağ geçmişi istatistikleri'),
        actions: [
          IconButton(
            tooltip: 'İstatistikleri yenile',
            onPressed: () =>
                ref.invalidate(historyStatisticsProvider(_selectedNetworkKey)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: profiles.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                    data: (items) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedNetworkKey ?? _allNetworksValue,
                      decoration: const InputDecoration(
                        labelText: 'İstatistik kapsamı',
                        prefixIcon: Icon(Icons.filter_alt_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: _allNetworksValue,
                          child: Text('Tüm ağlar'),
                        ),
                        ...items.map(
                          (profile) => DropdownMenuItem(
                            value: profile.networkKey,
                            child: Text(
                              profile.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedNetworkKey = value == _allNetworksValue
                            ? null
                            : value;
                      }),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: statistics.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => _StatisticsError(
                      onRetry: () => ref.invalidate(
                        historyStatisticsProvider(_selectedNetworkKey),
                      ),
                    ),
                    data: (value) => _StatisticsContent(statistics: value),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.statistics});

  final NetworkHistoryStatistics statistics;

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'İstatistik oluşturmak için en az bir tamamlanmış tarama gerekir.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Genel görünüm', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Aşağıdaki değerler cihazda tutulan en fazla 200 tarama kaydından hesaplanır.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              icon: Icons.radar_outlined,
              label: 'Tarama',
              value: '${statistics.totalScans}',
            ),
            _MetricCard(
              icon: Icons.router_outlined,
              label: 'Ağ',
              value: '${statistics.networkCount}',
            ),
            _MetricCard(
              icon: Icons.devices_outlined,
              label: 'Ortalama cihaz',
              value: statistics.averageDeviceCount.toStringAsFixed(1),
            ),
            _MetricCard(
              icon: Icons.timer_outlined,
              label: 'Ortalama süre',
              value: formatHistoryDuration(statistics.averageDuration),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DeviceCountTrendCard(statistics: statistics),
        const SizedBox(height: 12),
        _ChangeSummaryCard(statistics: statistics),
        const SizedBox(height: 12),
        _FrequentDevicesCard(devices: statistics.frequentDevices),
        const SizedBox(height: 12),
        Text(
          'Bu istatistikler yalnız uygulamanın gözlemleyebildiği cihazlara dayanır. '
          'Bir cihazın görünmemesi çevrimdışı, uyku modunda veya güvenlik duvarı arkasında olduğu anlamına gelebilir.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: SizedBox(
        width: 196,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(label, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceCountTrendCard extends StatelessWidget {
  const _DeviceCountTrendCard({required this.statistics});

  final NetworkHistoryStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final trend = statistics.trend;
    final firstDate = formatHistoryDateTime(trend.first.completedAt);
    final lastDate = formatHistoryDateTime(trend.last.completedAt);
    final semanticsLabel = trend
        .map(
          (point) =>
              '${formatHistoryDateTime(point.completedAt)}: ${point.deviceCount} cihaz',
        )
        .join(', ');
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cihaz sayısı eğilimi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Son ${trend.length} tarama • $firstDate — $lastDate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Tarama başına cihaz sayıları. $semanticsLabel',
              excludeSemantics: true,
              child: SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final point in trend)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Tooltip(
                            message:
                                '${formatHistoryDateTime(point.completedAt)}\n'
                                '${point.deviceCount} cihaz • ${point.newDeviceCount} yeni • '
                                '${point.missingDeviceCount} görülmeyen',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${point.deviceCount}',
                                    maxLines: 1,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor:
                                        (point.deviceCount /
                                                statistics
                                                    .maximumTrendDeviceCount)
                                            .clamp(0.08, 1),
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(
                                        minHeight: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeSummaryCard extends StatelessWidget {
  const _ChangeSummaryCard({required this.statistics});

  final NetworkHistoryStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Değişiklik özeti',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(
                    '${statistics.totalNewDeviceObservations} ilk gözlem',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: Text(
                    '${statistics.totalMissingDeviceObservations} görülmeyen kaydı',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text('${statistics.knownDeviceCount} bilinen cihaz'),
                ),
                Chip(
                  avatar: const Icon(Icons.help_outline, size: 18),
                  label: Text(
                    '${statistics.unclassifiedDeviceCount} tanımlanmamış cihaz',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequentDevicesCard extends StatelessWidget {
  const _FrequentDevicesCard({required this.devices});

  final List<KnownDeviceSummary> devices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'En sık gözlemlenen cihazlar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (devices.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Text('Henüz cihaz gözlem verisi yok.'),
              )
            else
              for (final device in devices)
                ListTile(
                  leading: Icon(
                    device.isKnown
                        ? Icons.verified_user_outlined
                        : Icons.devices_outlined,
                  ),
                  title: Text(device.effectiveDisplayName),
                  subtitle: Text(
                    '${device.observationCount} taramada • son IP ${device.lastIpAddress}',
                  ),
                  trailing: Text(
                    device.isKnown ? 'Bilinen' : 'Tanımsız',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsError extends StatelessWidget {
  const _StatisticsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Geçmiş istatistikleri okunamadı.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
