import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanControllerProvider);
    final controller = ref.read(scanControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpyDevDet'),
        actions: [
          IconButton(
            tooltip: 'Uygulama bilgisi',
            onPressed: () => _showAppInfo(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _SafetyNotice(),
                const SizedBox(height: 12),
                _ScanStatusCard(state: scanState),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: scanState.isBusy
                      ? controller.cancelScan
                      : controller.startScan,
                  icon: Icon(scanState.isBusy ? Icons.stop : Icons.radar),
                  label: Text(
                    scanState.isBusy ? 'Taramayı durdur' : 'Yerel ağı tara',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Gözlemlenen cihazlar (${scanState.devices.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (scanState.devices.isEmpty)
                  _EmptyDevices(state: scanState)
                else
                  ...scanState.devices.map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DeviceCard(device: device),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SpyDevDet',
      applicationVersion: '1.1.0',
      children: const [
        Text(
          'Uygulama yalnızca etkin yerel ağ bağlantısındaki özel IPv4 '
          'adreslerinde seçili TCP portlarını kontrol eder. Sonuçlar bir '
          'cihazın casus olduğunu kanıtlamaz ve tüm cihazların bulunacağını '
          'garanti etmez.',
        ),
      ],
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
                'ağlarda kullan. Tarama en fazla 254 özel IPv4 adresiyle ve '
                'sekiz yaygın TCP portuyla sınırlıdır.',
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
            Text(state.statusMessage),
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
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Tarama ilerlemesi yüzde ${(state.progress * 100).round()}',
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
      ScanPhase.completed =>
        'Seçili TCP portlarında yanıt veren cihaz bulunamadı. Bu sonuç ağda '
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

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final DeviceObservation device;

  @override
  Widget build(BuildContext context) {
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
                      device.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Text(device.ipAddress),
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'IP adresi', value: device.ipAddress),
              _DetailRow(
                label: 'Bulunma yöntemi',
                value: device.discoveryMethod,
              ),
              _DetailRow(
                label: 'Gözlemlenen servisler',
                value: device.services.isEmpty
                    ? 'Bilinmiyor'
                    : device.services.join(', '),
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
            ],
          ),
        ),
      ),
    );
  }
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
