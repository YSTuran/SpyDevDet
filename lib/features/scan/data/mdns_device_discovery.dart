import 'dart:io';
import 'dart:math' as math;

import 'package:multicast_dns/multicast_dns.dart';
import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation_merger.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

class MdnsDeviceDiscovery implements DeviceDiscovery {
  const MdnsDeviceDiscovery({
    this.queryTimeout = const Duration(milliseconds: 850),
  });

  static const _serviceEnumeration = '_services._dns-sd._udp.local';
  static const _maxConcurrentLookups = 12;
  static const _defaultServiceTypes = [
    '_http._tcp.local',
    '_https._tcp.local',
    '_rtsp._tcp.local',
    '_ipp._tcp.local',
    '_printer._tcp.local',
    '_googlecast._tcp.local',
    '_airplay._tcp.local',
    '_hap._tcp.local',
    '_workstation._tcp.local',
    '_device-info._tcp.local',
  ];

  final Duration queryTimeout;

  @override
  Future<DeviceDiscoveryResult> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async {
    if (cancellationToken.isCancelled) {
      return const DeviceDiscoveryResult.empty();
    }

    final client = MDnsClient();
    var started = false;
    var stopped = false;

    void stopClient() {
      if (started && !stopped) {
        stopped = true;
        client.stop();
      }
    }

    final removeCancelListener = cancellationToken.addCancelListener(
      stopClient,
    );
    try {
      await client.start(
        interfacesFactory: (type) =>
            _matchingInterfaces(type, plan.network.localIpv4),
        onError: (_) {},
      );
      started = true;
      if (cancellationToken.isCancelled) {
        return const DeviceDiscoveryResult.empty();
      }

      final advertisedTypes = await client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(_serviceEnumeration),
            timeout: queryTimeout,
          )
          .map((record) => _normalizeServiceType(record.domainName))
          .where((type) => type != null)
          .cast<String>()
          .take(32)
          .toList();
      final serviceTypes = <String>{
        ..._defaultServiceTypes,
        ...advertisedTypes,
      }.take(42).toList(growable: false);

      final pointerGroups = await _boundedMap(
        serviceTypes,
        maxConcurrent: _maxConcurrentLookups,
        cancellationToken: cancellationToken,
        operation: (serviceType) => client
            .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(serviceType),
              timeout: queryTimeout,
            )
            .toList(),
      );
      if (cancellationToken.isCancelled) {
        return const DeviceDiscoveryResult.empty();
      }

      final pointers = <String, _ServicePointer>{};
      for (final group in pointerGroups) {
        for (final pointer in group.value) {
          if (pointers.length >= 96) {
            break;
          }
          pointers['${group.item}|${pointer.domainName}'] = _ServicePointer(
            serviceType: group.item,
            domainName: pointer.domainName,
          );
        }
      }

      final selectedPointers = pointers.values.take(48).toList(growable: false);
      final recordGroups = await _boundedMap(
        selectedPointers,
        maxConcurrent: _maxConcurrentLookups,
        cancellationToken: cancellationToken,
        operation: (pointer) => _resolveService(client, pointer),
      );
      if (cancellationToken.isCancelled) {
        return const DeviceDiscoveryResult.empty();
      }
      final services = recordGroups
          .expand((group) => group.value)
          .take(64)
          .toList();
      final addressGroups = await _boundedMap(
        services,
        maxConcurrent: _maxConcurrentLookups,
        cancellationToken: cancellationToken,
        operation: (service) => client
            .lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(service.record.target),
              timeout: queryTimeout,
            )
            .toList(),
      );
      if (cancellationToken.isCancelled) {
        return const DeviceDiscoveryResult.empty();
      }

      final observations = <String, DeviceObservation>{};
      var ignoredResponses = 0;
      var addressRecordCount = 0;
      for (final group in addressGroups) {
        if (cancellationToken.isCancelled) {
          break;
        }
        final service = group.item;
        for (final addressRecord in group.value) {
          addressRecordCount++;
          final ipAddress = addressRecord.address.address;
          if (!_isAllowed(ipAddress, plan)) {
            ignoredResponses++;
            continue;
          }
          final observation = _observation(
            ipAddress: ipAddress,
            pointer: service.pointer,
            record: service.record,
            metadata: service.metadata,
          );
          final existing = observations[ipAddress];
          observations[ipAddress] = existing == null
              ? observation
              : const DeviceObservationMerger().merge(existing, observation);
        }
      }
      final devices = List<DeviceObservation>.unmodifiable(observations.values);
      return DeviceDiscoveryResult(
        devices: devices,
        metrics: DiscoveryMetrics(
          sentRequests:
              1 +
              serviceTypes.length +
              (selectedPointers.length * 2) +
              services.length,
          receivedResponses:
              pointers.length + services.length + addressRecordCount,
          acceptedResponses: devices.length,
          ignoredResponses: ignoredResponses,
          detail: '${pointers.length} servis duyurusu çözümlendi',
        ),
      );
    } on Object {
      if (cancellationToken.isCancelled) {
        return const DeviceDiscoveryResult.empty();
      }
      rethrow;
    } finally {
      removeCancelListener();
      stopClient();
    }
  }

  Future<List<_DiscoveredService>> _resolveService(
    MDnsClient client,
    _ServicePointer pointer,
  ) async {
    final groups = await Future.wait([
      client
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(pointer.domainName),
            timeout: queryTimeout,
          )
          .toList(),
      client
          .lookup<TxtResourceRecord>(
            ResourceRecordQuery.text(pointer.domainName),
            timeout: queryTimeout,
          )
          .toList(),
    ]);
    final records = groups[0].whereType<SrvResourceRecord>();
    final metadata = MdnsTxtMetadata.fromRecords(
      groups[1].whereType<TxtResourceRecord>(),
    );
    return records
        .map((record) => _DiscoveredService(pointer, record, metadata))
        .toList(growable: false);
  }

  Future<Iterable<NetworkInterface>> _matchingInterfaces(
    InternetAddressType type,
    String localIpv4,
  ) async {
    final interfaces = await NetworkInterface.list(
      type: type,
      includeLinkLocal: false,
      includeLoopback: false,
    );
    return interfaces.where(
      (interface) =>
          interface.addresses.any((address) => address.address == localIpv4),
    );
  }

  bool _isAllowed(String ipAddress, ScanPlan plan) {
    if (ipAddress == plan.network.localIpv4) {
      return false;
    }
    return plan.targets.contains(ipAddress) ||
        ipAddress == plan.network.gatewayIpv4;
  }

  DeviceObservation _observation({
    required String ipAddress,
    required _ServicePointer pointer,
    required SrvResourceRecord record,
    required MdnsTxtMetadata metadata,
  }) {
    final serviceLabel = '${pointer.serviceType} (${record.port})';
    final metadataDescription = metadata.summary;
    return DeviceObservation(
      id: 'device-$ipAddress',
      ipAddress: ipAddress,
      displayName: _instanceName(pointer.domainName, pointer.serviceType),
      macStatus: MacStatus.notObserved,
      services: [
        serviceLabel,
        if (metadataDescription != null) 'mDNS: $metadataDescription',
      ],
      discoveryMethod: 'mDNS',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.mdns,
          description: 'mDNS servis duyurusu: $serviceLabel',
          serviceType: pointer.serviceType,
          port: record.port,
          identifier: pointer.domainName,
        ),
        if (metadataDescription != null)
          DeviceEvidence(
            source: DeviceEvidenceSource.mdns,
            description: 'mDNS cihaz bilgisi: $metadataDescription',
            serviceType: pointer.serviceType,
            identifier: pointer.domainName,
          ),
      ],
    );
  }

  String? _normalizeServiceType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.length > 128 ||
        !RegExp(
          r'^_[a-z0-9-]+\._(?:tcp|udp)\.local\.?$',
        ).hasMatch(normalized)) {
      return null;
    }
    return normalized.endsWith('.')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  String _instanceName(String domainName, String serviceType) {
    final suffix = '.$serviceType';
    final raw = domainName.endsWith(suffix)
        ? domainName.substring(0, domainName.length - suffix.length)
        : domainName;
    final sanitized = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (sanitized.isEmpty) {
      return 'mDNS cihazı';
    }
    return sanitized.length <= 80 ? sanitized : sanitized.substring(0, 80);
  }
}

Future<List<({T item, R value})>> _boundedMap<T, R>(
  List<T> items, {
  required int maxConcurrent,
  required ScanCancellationToken cancellationToken,
  required Future<R> Function(T item) operation,
}) async {
  if (items.isEmpty || cancellationToken.isCancelled) {
    return const [];
  }
  final values = List<Object?>.filled(items.length, null);
  final completed = List<bool>.filled(items.length, false);
  var nextIndex = 0;

  Future<void> worker() async {
    while (!cancellationToken.isCancelled) {
      final index = nextIndex++;
      if (index >= items.length) {
        return;
      }
      values[index] = await operation(items[index]);
      completed[index] = true;
    }
  }

  final workerCount = math.min(maxConcurrent, items.length);
  await Future.wait(List.generate(workerCount, (_) => worker()));
  return [
    for (var index = 0; index < items.length; index++)
      if (completed[index]) (item: items[index], value: values[index] as R),
  ];
}

class _ServicePointer {
  const _ServicePointer({required this.serviceType, required this.domainName});

  final String serviceType;
  final String domainName;
}

class _DiscoveredService {
  const _DiscoveredService(this.pointer, this.record, this.metadata);

  final _ServicePointer pointer;
  final SrvResourceRecord record;
  final MdnsTxtMetadata metadata;
}

class MdnsTxtMetadata {
  const MdnsTxtMetadata(this.values);

  final Map<String, String> values;

  static const _allowedKeys = {
    'fn',
    'md',
    'model',
    'manufacturer',
    'mf',
    'product',
    'ty',
  };

  factory MdnsTxtMetadata.fromRecords(Iterable<TxtResourceRecord> records) {
    final values = <String, String>{};
    for (final record in records) {
      for (final line in record.text.split(RegExp(r'\r?\n'))) {
        final separator = line.indexOf('=');
        if (separator <= 0) {
          continue;
        }
        final key = line.substring(0, separator).trim().toLowerCase();
        if (!_allowedKeys.contains(key) || values.length >= 6) {
          continue;
        }
        final raw = line.substring(separator + 1);
        final sanitized = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
        if (sanitized.isNotEmpty) {
          values[key] = sanitized.length <= 80
              ? sanitized
              : sanitized.substring(0, 80);
        }
      }
    }
    return MdnsTxtMetadata(Map.unmodifiable(values));
  }

  String? get summary {
    if (values.isEmpty) {
      return null;
    }
    return values.entries
        .take(4)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
  }
}
