import 'dart:convert';

import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_quality.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

enum ScanReportExportFormat { json, csv, text }

extension ScanReportExportFormatText on ScanReportExportFormat {
  String get label => switch (this) {
    ScanReportExportFormat.json => 'JSON teknik rapor',
    ScanReportExportFormat.csv => 'CSV cihaz tablosu',
    ScanReportExportFormat.text => 'Okunabilir metin raporu',
  };

  String get extension => switch (this) {
    ScanReportExportFormat.json => 'json',
    ScanReportExportFormat.csv => 'csv',
    ScanReportExportFormat.text => 'txt',
  };

  String get mimeType => switch (this) {
    ScanReportExportFormat.json => 'application/json',
    ScanReportExportFormat.csv => 'text/csv',
    ScanReportExportFormat.text => 'text/plain',
  };
}

enum ScanReportPrivacyMode { masked, full }

extension ScanReportPrivacyModeText on ScanReportPrivacyMode {
  String get label => switch (this) {
    ScanReportPrivacyMode.masked => 'Gizlilik korumalı',
    ScanReportPrivacyMode.full => 'Tam teknik veri',
  };
}

class GeneratedScanReport {
  const GeneratedScanReport({
    required this.fileName,
    required this.mimeType,
    required this.content,
  });

  final String fileName;
  final String mimeType;
  final String content;
}

class ScanReportExporter {
  const ScanReportExporter();

  GeneratedScanReport generate({
    required ScanHistoryDetails details,
    required ScanReportExportFormat format,
    required ScanReportPrivacyMode privacyMode,
    required String applicationVersion,
  }) {
    final timestamp = details.summary.completedAt.toLocal();
    final name = 'spydevdet_${_fileTimestamp(timestamp)}.${format.extension}';
    final content = switch (format) {
      ScanReportExportFormat.json => _json(
        details,
        privacyMode,
        applicationVersion,
      ),
      ScanReportExportFormat.csv => _csv(details, privacyMode),
      ScanReportExportFormat.text => _text(
        details,
        privacyMode,
        applicationVersion,
      ),
    };
    return GeneratedScanReport(
      fileName: name,
      mimeType: format.mimeType,
      content: content,
    );
  }

  String _json(
    ScanHistoryDetails details,
    ScanReportPrivacyMode privacyMode,
    String applicationVersion,
  ) {
    final summary = details.summary;
    final masked = privacyMode == ScanReportPrivacyMode.masked;
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'applicationVersion': applicationVersion,
      'privacyMode': privacyMode.name,
      'scan': {
        'sessionId': summary.id,
        'network': masked ? 'masked' : summary.networkKey,
        'startedAt': summary.startedAt.toUtc().toIso8601String(),
        'completedAt': summary.completedAt.toUtc().toIso8601String(),
        'mode': summary.scanMode.name,
        'quality': summary.quality.level.name,
        'presenceComparable': summary.isPresenceComparable,
        'partial': summary.isPartial,
        'elapsedMillis': summary.elapsed.inMilliseconds,
        'deviceCount': summary.totalDeviceCount,
        'newDeviceCount': summary.newDeviceCount,
      },
      'methods': [
        for (final method in DiscoveryMethod.values)
          if (summary.methods[method] case final result?)
            {
              'method': method.name,
              'phase': result.phase.name,
              'deviceCount': result.deviceCount,
              'elapsedMillis': result.elapsed.inMilliseconds,
              'attemptedTargets': result.metrics.attemptedTargets,
              'sentRequests': result.metrics.sentRequests,
              'receivedResponses': result.metrics.receivedResponses,
              'acceptedResponses': result.metrics.acceptedResponses,
              'ignoredResponses': result.metrics.ignoredResponses,
              'timeoutCount': result.metrics.timeoutCount,
              if (!masked) 'detail': result.metrics.detail,
            },
      ],
      'devices': [
        for (var index = 0; index < details.devices.length; index++)
          _deviceJson(details.devices[index], index, privacyMode),
      ],
      'comparison': {
        'state': details.referenceComparison.state.name,
        'baselineKind': details.referenceComparison.baselineKind.name,
        'addedCount': details.referenceComparison.addedDevices.length,
        'missingCount': details.referenceComparison.missingDevices.length,
        'changedCount': details.referenceComparison.changedDevices.length,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, Object?> _deviceJson(
    DeviceObservation device,
    int index,
    ScanReportPrivacyMode privacyMode,
  ) {
    final masked = privacyMode == ScanReportPrivacyMode.masked;
    return {
      'name': masked ? 'Cihaz ${index + 1}' : device.effectiveDisplayName,
      'ipAddress': masked ? _maskIp(device.ipAddress) : device.ipAddress,
      'macAddress': masked ? _maskMac(device.macAddress) : device.macAddress,
      'macStatus': device.macStatus.name,
      'vendor': device.vendor,
      'category': device.effectiveCategory.name,
      'automaticCategory': device.category.name,
      'confidence': device.confidence.name,
      'familiarity': device.familiarity.name,
      'services': device.services,
      'discoveryMethod': device.discoveryMethod,
      'owned': device.isOwned,
      if (!masked) 'stableKey': device.stableKey,
      if (!masked) 'note': device.note,
      'evidence': [
        for (final evidence in device.evidence)
          {
            'source': evidence.source.name,
            'serviceType': evidence.serviceType,
            'port': evidence.port,
            if (!masked) 'description': evidence.description,
            if (!masked) 'identifier': evidence.identifier,
          },
      ],
    };
  }

  String _csv(ScanHistoryDetails details, ScanReportPrivacyMode privacyMode) {
    const headers = [
      'name',
      'ip_address',
      'mac_address',
      'vendor',
      'category',
      'confidence',
      'familiarity',
      'services',
      'note',
    ];
    final rows = <List<String>>[
      headers,
      for (var index = 0; index < details.devices.length; index++)
        _deviceCsv(details.devices[index], index, privacyMode),
    ];
    return '${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  List<String> _deviceCsv(
    DeviceObservation device,
    int index,
    ScanReportPrivacyMode privacyMode,
  ) {
    final masked = privacyMode == ScanReportPrivacyMode.masked;
    return [
      masked ? 'Cihaz ${index + 1}' : device.effectiveDisplayName,
      masked ? _maskIp(device.ipAddress) : device.ipAddress,
      masked ? _maskMac(device.macAddress) ?? '' : device.macAddress ?? '',
      device.vendor ?? '',
      device.effectiveCategory.label,
      device.confidence.label,
      device.familiarity.label,
      device.services.join(' | '),
      masked ? '' : device.note ?? '',
    ];
  }

  String _text(
    ScanHistoryDetails details,
    ScanReportPrivacyMode privacyMode,
    String applicationVersion,
  ) {
    final summary = details.summary;
    final masked = privacyMode == ScanReportPrivacyMode.masked;
    final buffer = StringBuffer()
      ..writeln('SpyDevDet tarama raporu')
      ..writeln('Rapor biçimi: 1')
      ..writeln('Uygulama sürümü: $applicationVersion')
      ..writeln('Gizlilik modu: ${privacyMode.label}')
      ..writeln('Tamamlanma: ${summary.completedAt.toLocal()}')
      ..writeln('Ağ: ${masked ? 'Gizlendi' : summary.networkKey}')
      ..writeln('Tarama modu: ${summary.scanMode.label}')
      ..writeln('Tarama kalitesi: ${summary.quality.level.label}')
      ..writeln('Cihaz sayısı: ${summary.totalDeviceCount}')
      ..writeln();
    for (var index = 0; index < details.devices.length; index++) {
      final device = details.devices[index];
      buffer
        ..writeln(
          '${index + 1}. '
          '${masked ? 'Cihaz ${index + 1}' : device.effectiveDisplayName}',
        )
        ..writeln(
          '   IP: '
          '${masked ? _maskIp(device.ipAddress) : device.ipAddress}',
        )
        ..writeln(
          '   MAC: '
          '${masked ? _maskMac(device.macAddress) : device.macAddress ?? 'Yok'}',
        )
        ..writeln('   Üretici: ${device.vendor ?? 'Bilinmiyor'}')
        ..writeln('   Tür: ${device.effectiveCategory.label}')
        ..writeln('   Güven: ${device.confidence.label}')
        ..writeln(
          '   Servisler: '
          '${device.services.isEmpty ? 'Gözlemlenmedi' : device.services.join(', ')}',
        );
      if (!masked && device.note?.trim().isNotEmpty == true) {
        buffer.writeln('   Not: ${device.note}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _maskIp(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return 'Gizlendi';
    return '${parts[0]}.${parts[1]}.${parts[2]}.x';
  }

  String? _maskMac(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(RegExp('[:-]'));
    if (parts.length < 3) return 'Gizlendi';
    return '${parts.take(3).join(':')}:xx:xx:xx';
  }

  String _csvCell(String value) {
    var safeValue = value.replaceAll(RegExp(r'[\t\r\n]'), ' ');
    final firstVisible = safeValue.trimLeft();
    if (firstVisible.isNotEmpty &&
        const {
          '=',
          '+',
          '-',
          '@',
          '＝',
          '＋',
          '－',
          '＠',
        }.contains(firstVisible[0])) {
      // Spreadsheet applications can execute cells that start with a formula
      // marker even when the CSV value is correctly quoted. A leading apostrophe
      // makes the cell explicit text while preserving the human-readable value.
      safeValue = "'$safeValue";
    }
    return '"${safeValue.replaceAll('"', '""')}"';
  }

  String _fileTimestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }
}
