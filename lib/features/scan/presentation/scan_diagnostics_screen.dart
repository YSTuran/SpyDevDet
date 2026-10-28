import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spy_dev_det/features/history/data/report_file_service.dart';
import 'package:spy_dev_det/features/scan/application/scan_controller.dart';
import 'package:spy_dev_det/features/scan/application/scan_state.dart';
import 'package:spy_dev_det/features/scan/domain/diagnostic_bundle_export.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class ScanDiagnosticsScreen extends ConsumerWidget {
  const ScanDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);
    final network = state.network;
    final report = state.report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarama tanılama'),
        actions: [
          IconButton(
            tooltip: 'Gizlilik korumalı tanılamayı dışa aktar',
            onPressed: state.phase == ScanPhase.idle
                ? null
                : () => _exportDiagnostics(context, state),
            icon: const Icon(Icons.ios_share_outlined),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ağ ve kapsam',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _Line(
                          label: 'Yerel adres',
                          value: network?.cidr ?? 'Henüz bilinmiyor',
                        ),
                        _Line(
                          label: 'Bağdaştırıcı',
                          value: network?.interfaceName ?? 'Bilinmiyor',
                        ),
                        _Line(
                          label: 'Bağlantı türü',
                          value: network == null
                              ? 'Bilinmiyor'
                              : network.isWifi
                              ? 'Wi-Fi'
                              : network.isEthernet
                              ? 'Ethernet'
                              : 'Desteklenmeyen',
                        ),
                        _Line(
                          label: 'Ağ geçidi',
                          value: network?.gatewayIpv4 ?? 'Bilinmiyor',
                        ),
                        _Line(
                          label: 'Tarama aralığı',
                          value: state.scanRange ?? 'Henüz hesaplanmadı',
                        ),
                        _Line(
                          label: 'Hedefler',
                          value:
                              '${state.scannedTargets}/${state.totalTargets}',
                        ),
                        _Line(
                          label: 'Aralık sınırı',
                          value: state.rangeTruncated
                              ? '254 hedefle sınırlandı'
                              : 'Sınırlandırılmadı',
                        ),
                        _Line(
                          label: 'Sonuç',
                          value: report == null
                              ? 'Henüz rapor yok'
                              : report.isPartial
                              ? 'Kısmi tarama'
                              : 'Karşılaştırılabilir tam tarama',
                        ),
                        if (state.errorCode case final errorCode?)
                          _Line(label: 'Hata kodu', value: errorCode),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (report == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Tanılama ayrıntıları tarama başladıktan sonra oluşur.',
                      ),
                    ),
                  )
                else
                  ...DiscoveryMethod.values.map(
                    (method) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MethodDiagnostics(
                        result:
                            report.methods[method] ??
                            DiscoveryMethodResult.waiting(method),
                      ),
                    ),
                  ),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Yanıt alınmaması cihazın kapalı olduğunu kanıtlamaz. '
                      'İstemci izolasyonu, güvenlik duvarı, uyku modu veya cihazın '
                      'keşif protokollerine yanıt vermemesi sonucu etkileyebilir.',
                    ),
                  ),
                ),
                Card(
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Tanılama paketi yalnız sen dışa aktardığında oluşturulur. '
                      'IP adresleri maskelenir; MAC adresleri ve cihaz kimlikleri '
                      'pakete eklenmez. Uygulama paketi otomatik yüklemez.',
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

  Future<void> _exportDiagnostics(BuildContext context, ScanState state) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final report = const DiagnosticBundleExporter().generate(
        applicationVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        operatingSystem: Platform.operatingSystem,
        operatingSystemVersion: Platform.operatingSystemVersion,
        scanPhase: state.phase.name,
        statusMessage: state.statusMessage,
        scanMode: state.scanMode,
        scannedTargets: state.scannedTargets,
        totalTargets: state.totalTargets,
        rangeTruncated: state.rangeTruncated,
        network: state.network,
        scanRange: state.scanRange,
        report: state.report,
        errorCode: state.errorCode,
      );
      final result = await const ReportFileService().saveOrShare(
        report,
        subject: 'SpyDevDet gizlilik korumalı tanılama paketi',
      );
      if (!context.mounted || result == ReportFileResult.cancelled) return;
      final message = result == ReportFileResult.saved
          ? 'Tanılama paketi kaydedildi'
          : 'Tanılama paketi paylaşım için hazırlandı';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanılama paketi oluşturulamadı')),
      );
    }
  }
}

class _MethodDiagnostics extends StatelessWidget {
  const _MethodDiagnostics({required this.result});

  final DiscoveryMethodResult result;

  @override
  Widget build(BuildContext context) {
    final metrics = result.metrics;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _color(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.method.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(result.phase.label)),
              ],
            ),
            const SizedBox(height: 8),
            _Line(label: 'Gözlemlenen cihaz', value: '${result.deviceCount}'),
            _Line(label: 'Süre', value: '${result.elapsed.inMilliseconds} ms'),
            if (metrics.attemptedTargets > 0)
              _Line(
                label: 'Kontrol edilen hedef',
                value: '${metrics.attemptedTargets}',
              ),
            if (metrics.hasValues) ...[
              _Line(
                label: 'Gönderilen istek',
                value: '${metrics.sentRequests}',
              ),
              _Line(
                label: 'Alınan yanıt',
                value: '${metrics.receivedResponses}',
              ),
              _Line(
                label: 'Kabul edilen yanıt',
                value: '${metrics.acceptedResponses}',
              ),
              _Line(
                label: 'Yok sayılan yanıt',
                value: '${metrics.ignoredResponses}',
              ),
              if (metrics.timeoutCount > 0)
                _Line(label: 'Zaman aşımı', value: '${metrics.timeoutCount}'),
              if (metrics.multicastLockAcquired case final acquired?)
                _Line(
                  label: 'Multicast erişimi',
                  value: acquired ? 'Alındı' : 'Alınamadı',
                ),
              if (metrics.detail case final detail?)
                _Line(label: 'Teknik açıklama', value: detail),
            ],
            if (result.userMessage case final message?) ...[
              const SizedBox(height: 6),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (result.phase) {
    DiscoveryMethodPhase.completed => Icons.check_circle_outline,
    DiscoveryMethodPhase.platformRestricted => Icons.info_outline,
    DiscoveryMethodPhase.running => Icons.sync,
    DiscoveryMethodPhase.failed ||
    DiscoveryMethodPhase.unavailable => Icons.warning_amber_outlined,
    DiscoveryMethodPhase.cancelled => Icons.cancel_outlined,
    DiscoveryMethodPhase.skipped => Icons.skip_next_outlined,
    DiscoveryMethodPhase.waiting => Icons.schedule,
  };

  Color _color(BuildContext context) => switch (result.phase) {
    DiscoveryMethodPhase.completed => Colors.green,
    DiscoveryMethodPhase.platformRestricted => Colors.orange,
    DiscoveryMethodPhase.running => Theme.of(context).colorScheme.primary,
    DiscoveryMethodPhase.failed ||
    DiscoveryMethodPhase.unavailable => Theme.of(context).colorScheme.error,
    _ => Theme.of(context).colorScheme.outline,
  };
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
