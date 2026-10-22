import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spy_dev_det/features/history/presentation/reference_comparison_card.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/domain/device_attention.dart';
import 'package:spy_dev_det/features/scan/domain/device_filter.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/discovery_coverage_advisor.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_quality.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';
import 'package:spy_dev_det/features/scan/domain/service_catalog.dart';
import 'package:spy_dev_det/features/scan/presentation/scan_diagnostics_screen.dart';
import 'package:spy_dev_det/features/scan/presentation/device_profile_editor.dart';
import 'package:spy_dev_det/features/scan/presentation/scan_quality_card.dart';

part 'scan_controls.dart';
part 'scan_device_card.dart';
part 'scan_status_sections.dart';

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
        toolbarHeight: 72,
        title: const _ScanAppTitle(),
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
                _ScanActionPanel(
                  state: scanState,
                  onPressed: scanState.phase == ScanPhase.saving
                      ? null
                      : scanState.isBusy
                      ? controller.cancelScan
                      : controller.startScan,
                ),
                const SizedBox(height: 12),
                _ScanModeSelector(
                  selected: scanState.scanMode,
                  enabled: !scanState.isBusy,
                  onChanged: controller.selectScanMode,
                ),
                const SizedBox(height: 12),
                _ScanStatusCard(state: scanState),
                const SizedBox(height: 12),
                const _SafetyNotice(),
                const SizedBox(height: 20),
                if (scanState.phase == ScanPhase.completed &&
                    scanState.devices.isNotEmpty) ...[
                  _ResultSummary(devices: scanState.devices),
                  const SizedBox(height: 20),
                ],
                if (scanState.phase == ScanPhase.completed &&
                    scanState.report != null) ...[
                  ScanQualityCard(
                    assessment: const ScanQualityEvaluator().evaluateReport(
                      scanState.report!,
                      rangeTruncated: scanState.rangeTruncated,
                      noDevicesObserved: scanState.devices.length <= 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (scanState.phase == ScanPhase.completed &&
                    scanState.referenceComparison != null) ...[
                  ReferenceComparisonCard(
                    comparison: scanState.referenceComparison!,
                  ),
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
      // Uygulama bilgisi alınamasa da açıklama penceresi açılabilir.
    }
    if (!context.mounted) return;
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
    if (edit == null || !context.mounted) return;
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

class _ScanAppTitle extends StatelessWidget {
  const _ScanAppTitle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.security_outlined, color: scheme.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SpyDevDet', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Yerel ağ görünürlüğü',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
