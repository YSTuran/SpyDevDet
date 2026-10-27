import 'dart:convert';

import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class ScanHistoryCodec {
  const ScanHistoryCodec();

  String encodeMethods(Map<DiscoveryMethod, DiscoveryMethodResult> methods) {
    return jsonEncode({
      for (final entry in methods.entries)
        entry.key.name: {
          'phase': entry.value.phase.name,
          'deviceCount': entry.value.deviceCount,
          'elapsedMillis': entry.value.elapsed.inMilliseconds,
          'userMessage': entry.value.userMessage,
          'metrics': {
            'attemptedTargets': entry.value.metrics.attemptedTargets,
            'sentRequests': entry.value.metrics.sentRequests,
            'receivedResponses': entry.value.metrics.receivedResponses,
            'acceptedResponses': entry.value.metrics.acceptedResponses,
            'ignoredResponses': entry.value.metrics.ignoredResponses,
            'timeoutCount': entry.value.metrics.timeoutCount,
            'multicastLockAcquired': entry.value.metrics.multicastLockAcquired,
            'detail': entry.value.metrics.detail,
          },
        },
    });
  }

  Map<DiscoveryMethod, DiscoveryMethodResult> decodeMethods(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }
      final methods = <DiscoveryMethod, DiscoveryMethodResult>{};
      for (final method in DiscoveryMethod.values) {
        final value = decoded[method.name];
        if (value is! Map<String, dynamic>) {
          if (method == DiscoveryMethod.netbios) {
            methods[method] = const DiscoveryMethodResult(
              method: DiscoveryMethod.netbios,
              phase: DiscoveryMethodPhase.completed,
              userMessage:
                  'Bu kayıt NetBIOS ayrı raporlanmadan önce oluşturuldu.',
            );
          } else if (method == DiscoveryMethod.reachability ||
              method == DiscoveryMethod.onvif) {
            methods[method] = DiscoveryMethodResult(
              method: method,
              phase: DiscoveryMethodPhase.unavailable,
              userMessage: 'Bu yöntem eski uygulama sürümünde mevcut değildi.',
            );
          }
          continue;
        }
        methods[method] = DiscoveryMethodResult(
          method: method,
          phase: enumByName(
            DiscoveryMethodPhase.values,
            value['phase'] as String?,
            DiscoveryMethodPhase.failed,
          ),
          deviceCount: value['deviceCount'] as int? ?? 0,
          elapsed: Duration(milliseconds: value['elapsedMillis'] as int? ?? 0),
          userMessage: value['userMessage'] as String?,
          metrics: _decodeMetrics(value['metrics']),
        );
      }
      return Map.unmodifiable(methods);
    } on FormatException {
      return const {};
    }
  }

  String encodeEvidence(List<DeviceEvidence> evidence) => jsonEncode(
    evidence
        .map(
          (item) => {
            'source': item.source.name,
            'description': item.description,
            'serviceType': item.serviceType,
            'port': item.port,
            'identifier': item.identifier,
          },
        )
        .toList(),
  );

  List<DeviceEvidence> decodeEvidence(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) {
        return const [];
      }
      return List.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map(
          (item) => DeviceEvidence(
            source: enumByName(
              DeviceEvidenceSource.values,
              item['source'] as String?,
              DeviceEvidenceSource.network,
            ),
            description: item['description'] as String? ?? 'Kayıtlı kanıt',
            serviceType: item['serviceType'] as String?,
            port: item['port'] as int?,
            identifier: item['identifier'] as String?,
          ),
        ),
      );
    } on FormatException {
      return const [];
    }
  }

  String encodeMissingDevices(List<MissingDeviceSummary> devices) => jsonEncode(
    devices
        .map(
          (device) => {
            'stableKey': device.stableKey,
            'displayName': device.displayName,
            'lastIpAddress': device.lastIpAddress,
          },
        )
        .toList(),
  );

  List<MissingDeviceSummary> decodeMissingDevices(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) {
        return const [];
      }
      return List.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map(
          (item) => MissingDeviceSummary(
            stableKey: item['stableKey'] as String? ?? '',
            displayName: item['displayName'] as String? ?? 'Bilinmeyen cihaz',
            lastIpAddress: item['lastIpAddress'] as String? ?? 'Bilinmiyor',
          ),
        ),
      );
    } on FormatException {
      return const [];
    }
  }

  List<String> decodeStringList(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is List
          ? List.unmodifiable(decoded.whereType<String>())
          : const [];
    } on FormatException {
      return const [];
    }
  }

  T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  T? enumByNameOrNull<T extends Enum>(List<T> values, String? name) {
    if (name == null) {
      return null;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  DiscoveryMetrics _decodeMetrics(Object? source) {
    if (source is! Map<String, dynamic>) {
      return const DiscoveryMetrics();
    }
    int readCount(String key) => (source[key] as num?)?.toInt() ?? 0;
    return DiscoveryMetrics(
      attemptedTargets: readCount('attemptedTargets'),
      sentRequests: readCount('sentRequests'),
      receivedResponses: readCount('receivedResponses'),
      acceptedResponses: readCount('acceptedResponses'),
      ignoredResponses: readCount('ignoredResponses'),
      timeoutCount: readCount('timeoutCount'),
      multicastLockAcquired: source['multicastLockAcquired'] as bool?,
      detail: source['detail'] as String?,
    );
  }
}
