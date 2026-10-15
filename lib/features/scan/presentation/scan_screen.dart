import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';
import 'package:spy_dev_det/features/history/presentation/history_screen.dart';

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
            tooltip: 'Tarama geçmişi',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const HistoryScreen(),
              ),
            ),
            icon: const Icon(Icons.history),
          ),
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
                      child: _DeviceCard(
                        device: device,
                        onManage: () => _showDeviceProfileEditor(
                          context,
                          controller,
                          device,
                        ),
                      ),
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
      applicationVersion: '1.2.0',
      children: const [
        Text(
          'Uygulama etkin yerel ağdaki özel IPv4 adreslerinde seçili TCP '
          'portlarını kontrol eder; mDNS ve SSDP servis duyurularını dinler. Sonuçlar bir '
          'cihazın casus olduğunu kanıtlamaz ve tüm cihazların bulunacağını '
          'garanti etmez.',
        ),
      ],
    );
  }

  Future<void> _showDeviceProfileEditor(
    BuildContext context,
    ScanController controller,
    DeviceObservation device,
  ) async {
    final nameController = TextEditingController(text: device.customName);
    final noteController = TextEditingController(text: device.note);
    var isKnown = device.isKnown;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cihaz profilini düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Özel cihaz adı',
                    hintText: 'Örneğin: Salon televizyonu',
                  ),
                ),
                TextField(
                  controller: noteController,
                  maxLength: 240,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Not',
                    hintText: 'İsteğe bağlı yerel not',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isKnown,
                  onChanged: (value) =>
                      setDialogState(() => isKnown = value ?? false),
                  title: const Text('Bu cihazı tanıyorum'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true || !context.mounted) {
      nameController.dispose();
      noteController.dispose();
      return;
    }
    try {
      await controller.updateDeviceProfile(
        device: device,
        isKnown: isKnown,
        customName: nameController.text,
        note: noteController.text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihaz profili kaydedildi')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihaz profili kaydedilemedi')),
        );
      }
    } finally {
      nameController.dispose();
      noteController.dispose();
    }
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
            if (state.report case final report?) ...[
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 6),
              Text(
                'Keşif yöntemleri',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ...DiscoveryMethod.values.map(
                (method) => _MethodResultRow(
                  result:
                      report.methods[method] ??
                      DiscoveryMethodResult.waiting(method),
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

class _MethodResultRow extends StatelessWidget {
  const _MethodResultRow({required this.result});

  final DiscoveryMethodResult result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.phase) {
      DiscoveryMethodPhase.completed => Colors.green,
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

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onManage});

  final DeviceObservation device;
  final VoidCallback onManage;

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
                    avatar: Icon(_categoryIcon(device.category), size: 18),
                    label: Text(device.category.label),
                  ),
                  Chip(label: Text(device.confidence.label)),
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Padding(
            padding: EdgeInsets.zero,
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
                      '${device.category.label} • ${device.confidence.label}',
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
                if (device.familiarity != DeviceFamiliarity.unclassified)
                  _DetailRow(
                    label: 'Tanıma durumu',
                    value: device.familiarity.label,
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
                if (device.category == DeviceCategory.cameraCandidate)
                  Text(
                    'Kamera adayı etiketi yalnızca ağ servislerine dayanır; '
                    'cihazın gizli veya kötü amaçlı olduğunu kanıtlamaz.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (device.stableKey != null) ...[
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
