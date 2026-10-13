import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/scan/application/fake_scan_controller.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(fakeScanControllerProvider);
    final controller = ref.read(fakeScanControllerProvider.notifier);

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _DemoNotice(),
            const SizedBox(height: 12),
            _ScanStatusCard(state: scanState),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: scanState.isScanning
                  ? controller.cancelScan
                  : controller.startScan,
              icon: Icon(scanState.isScanning ? Icons.stop : Icons.radar),
              label: Text(
                scanState.isScanning
                    ? 'Taramayı durdur'
                    : 'Demo taramayı başlat',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bulunan cihazlar (${scanState.devices.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (scanState.devices.isEmpty)
              const _EmptyDevices()
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
    );
  }

  void _showAppInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SpyDevDet',
      applicationVersion: '0.1.0-dev',
      children: const [
        Text(
          'Bu ilk iskelet gerçek ağı taramaz. Ağ keşfi bir sonraki adımda '
          'eklenecektir.',
        ),
      ],
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.science_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Demo modu: Sonuçlar uygulama akışını sınamak için '
                'üretilmektedir. Henüz gerçek ağ taraması yapılmaz.',
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
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Tarama ilerlemesi yüzde ${(state.progress * 100).round()}',
              child: LinearProgressIndicator(
                value: state.phase == ScanPhase.idle ? 0 : state.progress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Henüz cihaz yok. Demo taramayı başlatarak akışı sınayabilirsin.',
              textAlign: TextAlign.center,
            ),
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
            width: 100,
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
