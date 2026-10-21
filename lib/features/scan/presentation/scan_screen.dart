import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/domain/device_attention.dart';
import 'package:spy_dev_det/features/scan/domain/device_filter.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/discovery_coverage_advisor.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';
import 'package:spy_dev_det/features/scan/domain/service_catalog.dart';
import 'package:spy_dev_det/features/scan/presentation/scan_diagnostics_screen.dart';
import 'package:spy_dev_det/features/scan/presentation/device_profile_editor.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  DeviceFilterOption _filter = DeviceFilterOption.all;
  DeviceSortOption _sort = DeviceSortOption.ipAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref
          .read(scanControllerProvider.notifier)
          .cancelScan(
            message:
                'Tarama uygulama arka plana geçtiği için güvenli biçimde durduruldu',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);
    final controller = ref.read(scanControllerProvider.notifier);
    final displayedDevices = const DeviceListFilter().apply(
      scanState.devices,
      query: _searchController.text,
      filter: _filter,
      sort: _sort,
    );

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
                  onPressed: scanState.phase == ScanPhase.saving
                      ? null
                      : scanState.isBusy
                      ? controller.cancelScan
                      : controller.startScan,
                  icon: Icon(
                    scanState.phase == ScanPhase.saving
                        ? Icons.save_outlined
                        : scanState.isBusy
                        ? Icons.stop
                        : Icons.radar,
                  ),
                  label: Text(
                    scanState.phase == ScanPhase.saving
                        ? 'Geçmişe kaydediliyor'
                        : scanState.isBusy
                        ? 'Taramayı durdur'
                        : 'Yerel ağı tara',
                  ),
                ),
                const SizedBox(height: 12),
                _ScanModeSelector(
                  selected: scanState.scanMode,
                  enabled: !scanState.isBusy,
                  onChanged: controller.selectScanMode,
                ),
                const SizedBox(height: 20),
                if (scanState.phase == ScanPhase.completed &&
                    scanState.devices.isNotEmpty) ...[
                  _ResultSummary(devices: scanState.devices),
                  const SizedBox(height: 20),
                ],
                if (scanState.phase == ScanPhase.completed &&
                    scanState.report != null) ...[
                  _CoverageNotice(
                    messages: const DiscoveryCoverageAdvisor().explain(
                      methods: scanState.report!.methods,
                      rangeTruncated: scanState.rangeTruncated,
                      noDevicesObserved: scanState.devices.length <= 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (scanState.devices.isNotEmpty) ...[
                  _DeviceFilters(
                    controller: _searchController,
                    filter: _filter,
                    sort: _sort,
                    onQueryChanged: (_) => setState(() {}),
                    onFilterChanged: (value) => setState(() => _filter = value),
                    onSortChanged: (value) => setState(() => _sort = value),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  displayedDevices.length == scanState.devices.length
                      ? 'Gözlemlenen cihazlar (${scanState.devices.length})'
                      : 'Gözlemlenen cihazlar '
                            '(${displayedDevices.length}/${scanState.devices.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (scanState.devices.isEmpty)
                  _EmptyDevices(state: scanState)
                else if (displayedDevices.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Arama ve filtrelerle eşleşen cihaz bulunamadı.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...displayedDevices.map(
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

  Future<void> _showAppInfo(BuildContext context) async {
    var version = 'Bilinmiyor';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.buildNumber.isEmpty
          ? packageInfo.version
          : '${packageInfo.version} (${packageInfo.buildNumber})';
    } on Object {
      // Application metadata is informational; the dialog can still open if
      // the platform does not provide it.
    }
    if (!context.mounted) {
      return;
    }
    showAboutDialog(
      context: context,
      applicationName: 'SpyDevDet',
      applicationVersion: version,
      children: const [
        Text(
          'Uygulama etkin yerel ağdaki özel IPv4 adreslerinde erişilebilirliği ve seçili TCP '
          'portlarını kontrol eder; mDNS, SSDP ve ONVIF servis duyurularını dinler. Sonuçlar bir '
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
    final edit = await showDeviceProfileEditor(
      context,
      isKnown: device.isKnown,
      isOwned: device.isOwned,
      customName: device.customName,
      note: device.note,
      categoryOverride: device.categoryOverride,
    );
    if (edit == null || !context.mounted) {
      return;
    }
    try {
      await controller.updateDeviceProfile(
        device: device,
        isKnown: edit.isKnown,
        customName: edit.customName,
        note: edit.note,
        isOwned: edit.isOwned,
        categoryOverride: edit.categoryOverride,
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
    }
  }
}

class _ScanModeSelector extends StatelessWidget {
  const _ScanModeSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final ScanMode selected;
  final bool enabled;
  final ValueChanged<ScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tarama modu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ScanMode>(
                segments: ScanMode.values
                    .map(
                      (mode) => ButtonSegment<ScanMode>(
                        value: mode,
                        icon: Icon(
                          mode == ScanMode.quick
                              ? Icons.bolt_outlined
                              : Icons.manage_search_outlined,
                        ),
                        label: Text(mode.label),
                      ),
                    )
                    .toList(growable: false),
                selected: {selected},
                onSelectionChanged: enabled
                    ? (selection) => onChanged(selection.first)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selected.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceFilters extends StatelessWidget {
  const _DeviceFilters({
    required this.controller,
    required this.filter,
    required this.sort,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final DeviceFilterOption filter;
  final DeviceSortOption sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DeviceFilterOption> onFilterChanged;
  final ValueChanged<DeviceSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                labelText: 'Cihazlarda ara',
                hintText: 'Ad, IP, MAC, üretici veya servis',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final filterField = DropdownButtonFormField<DeviceFilterOption>(
                  initialValue: filter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filtre',
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: DeviceFilterOption.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onFilterChanged(value);
                    }
                  },
                );
                final sortField = DropdownButtonFormField<DeviceSortOption>(
                  initialValue: sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sırala',
                    prefixIcon: Icon(Icons.sort),
                  ),
                  items: DeviceSortOption.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onSortChanged(value);
                    }
                  },
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    children: [
                      filterField,
                      const SizedBox(height: 12),
                      sortField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: filterField),
                    const SizedBox(width: 12),
                    Expanded(child: sortField),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageNotice extends StatelessWidget {
  const _CoverageNotice({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }
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
                Chip(label: Text('$newCount yeni')),
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
