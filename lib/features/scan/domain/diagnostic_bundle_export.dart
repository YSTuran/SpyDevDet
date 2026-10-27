import 'dart:convert';

import 'package:spy_dev_det/features/history/domain/scan_report_export.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class DiagnosticBundleExporter {
  const DiagnosticBundleExporter();

  GeneratedScanReport generate({
    required String applicationVersion,
    required String operatingSystem,
    required String operatingSystemVersion,
    required String scanPhase,
    required String statusMessage,
    required ScanMode scanMode,
    required int scannedTargets,
    required int totalTargets,
    required bool rangeTruncated,
    required NetworkSnapshot? network,
    required String? scanRange,
    required ScanReport? report,
    String? errorCode,
    DateTime? generatedAt,
  }) {
    final createdAt = (generatedAt ?? DateTime.now()).toUtc();
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'generatedAt': createdAt.toIso8601String(),
      'privacy': {
        'mode': 'masked',
        'ipAddressesMasked': true,
        'macAddressesIncluded': false,
        'deviceIdentifiersIncluded': false,
        'automaticUpload': false,
      },
      'application': {'version': applicationVersion},
      'platform': {
        'operatingSystem': operatingSystem,
        'operatingSystemVersion': operatingSystemVersion,
      },
      'scan': {
        'phase': scanPhase,
        'mode': scanMode.name,
        'status': _maskText(statusMessage),
        'errorCode': errorCode,
        'scannedTargets': scannedTargets,
        'totalTargets': totalTargets,
        'rangeTruncated': rangeTruncated,
        'scanRange': _maskText(scanRange),
        'partial': report?.isPartial,
        'presenceComparable': report?.canComparePresence,
        'startedAt': report?.startedAt.toUtc().toIso8601String(),
        'completedAt': report?.completedAt?.toUtc().toIso8601String(),
      },
      'network': network == null
          ? null
          : {
              'connectionType': _connectionType(network),
              'prefixLength': network.prefixLength,
              'localIpv4': _maskIpv4(network.localIpv4),
              'gatewayIpv4': _maskIpv4(network.gatewayIpv4),
              'vpnActive': network.isVpn,
            },
      'methods': [
        for (final method in DiscoveryMethod.values)
          if (report?.methods[method] case final result?)
            {
              'method': method.name,
              'statusCode':
                  'DISCOVERY_${method.name.toUpperCase()}_${result.phase.name.toUpperCase()}',
              'phase': result.phase.name,
              'deviceCount': result.deviceCount,
              'elapsedMillis': result.elapsed.inMilliseconds,
              'message': _maskText(result.userMessage),
              'metrics': {
                'attemptedTargets': result.metrics.attemptedTargets,
                'sentRequests': result.metrics.sentRequests,
                'receivedResponses': result.metrics.receivedResponses,
                'acceptedResponses': result.metrics.acceptedResponses,
                'ignoredResponses': result.metrics.ignoredResponses,
                'timeoutCount': result.metrics.timeoutCount,
                'multicastLockAcquired': result.metrics.multicastLockAcquired,
                'detail': _maskText(result.metrics.detail),
              },
            },
      ],
    };
    return GeneratedScanReport(
      fileName: 'spydevdet_diagnostic_${_fileTimestamp(createdAt)}.json',
      mimeType: 'application/json',
      content: const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  String _connectionType(NetworkSnapshot network) {
    if (network.isWifi) return 'wifi';
    if (network.isEthernet) return 'ethernet';
    return 'unsupported';
  }

  String? _maskIpv4(String? value) {
    if (value == null) return null;
    final parts = value.split('.');
    if (parts.length != 4) return 'masked';
    return '${parts[0]}.${parts[1]}.${parts[2]}.x';
  }

  String? _maskText(String? value) {
    if (value == null) return null;
    final withoutIpv4 = value.replaceAllMapped(
      RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b'),
      (match) => _maskIpv4(match.group(0)) ?? 'masked',
    );
    return withoutIpv4.replaceAll(
      RegExp(r'\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b'),
      'xx:xx:xx:xx:xx:xx',
    );
  }

  String _fileTimestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }
}
