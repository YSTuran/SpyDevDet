import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spy_dev_det/features/history/data/report_file_service.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/domain/scan_report_export.dart';

Future<void> exportScanReport(
  BuildContext context,
  ScanHistoryDetails details,
) async {
  var format = ScanReportExportFormat.text;
  var privacyMode = ScanReportPrivacyMode.masked;
  final selection =
      await showDialog<
        ({ScanReportExportFormat format, ScanReportPrivacyMode privacy})
      >(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Tarama raporunu dışa aktar'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ScanReportExportFormat>(
                    initialValue: format,
                    decoration: const InputDecoration(
                      labelText: 'Rapor biçimi',
                    ),
                    items: ScanReportExportFormat.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => format = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ScanReportPrivacyMode>(
                    initialValue: privacyMode,
                    decoration: const InputDecoration(labelText: 'Gizlilik'),
                    items: ScanReportPrivacyMode.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => privacyMode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    privacyMode == ScanReportPrivacyMode.masked
                        ? 'IP ve MAC adresleri maskelenir; özel adlar, notlar, '
                              'ağ kimliği ve kanıt tanımlayıcıları çıkarılır.'
                        : 'Tam rapor IP, MAC, özel cihaz adı, yerel not ve ağ '
                              'kimliği içerebilir. Dosyayı yalnız güvendiğin '
                              'kişilerle paylaş.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Vazgeç'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, (
                  format: format,
                  privacy: privacyMode,
                )),
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Devam et'),
              ),
            ],
          ),
        ),
      );
  if (selection == null || !context.mounted) return;
  if (selection.privacy == ScanReportPrivacyMode.full) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tam teknik veri dışa aktarılsın mı?'),
        content: const Text(
          'Bu dosya yerel ağ adresleri, cihaz kimlikleri ve kullanıcı '
          'notları gibi özel bilgiler içerebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tam raporu oluştur'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }
  try {
    var version = 'Bilinmiyor';
    try {
      final package = await PackageInfo.fromPlatform();
      version = package.buildNumber.isEmpty
          ? package.version
          : '${package.version} (${package.buildNumber})';
    } on Object {
      // Rapor sürüm bilgisi olmadan da üretilebilir.
    }
    final report = const ScanReportExporter().generate(
      details: details,
      format: selection.format,
      privacyMode: selection.privacy,
      applicationVersion: version,
    );
    final result = await const ReportFileService().saveOrShare(report);
    if (!context.mounted || result == ReportFileResult.cancelled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == ReportFileResult.saved
              ? 'Rapor kaydedildi'
              : 'Rapor paylaşım menüsüne gönderildi',
        ),
      ),
    );
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rapor dışa aktarılamadı')));
    }
  }
}
