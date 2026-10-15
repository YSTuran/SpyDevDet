import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation_merger.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

class MdnsDeviceDiscovery implements DeviceDiscovery {
  const MdnsDeviceDiscovery({
    this.queryTimeout = const Duration(milliseconds: 850),
  });

  static const _serviceTypes = [
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
  Future<List<DeviceObservation>> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async {
    if (cancellationToken.isCancelled) {
      return const [];
    }

    final client = MDnsClient();
    var started = false;
    try {
      await client.start(
        interfacesFactory: (type) =>
            _matchingInterfaces(type, plan.network.localIpv4),
        onError: (_) {},
      );
      started = true;
      if (cancellationToken.isCancelled) {
        return const [];
      }

      final pointerGroups = await Future.wait(
        _serviceTypes.map(
          (serviceType) => client
              .lookup<PtrResourceRecord>(
                ResourceRecordQuery.serverPointer(serviceType),
                timeout: queryTimeout,
              )
              .toList(),
        ),
      );

      final pointers = <String, _ServicePointer>{};
      for (var index = 0; index < pointerGroups.length; index++) {
        for (final pointer in pointerGroups[index]) {
          pointers['${_serviceTypes[index]}|${pointer.domainName}'] =
              _ServicePointer(
                serviceType: _serviceTypes[index],
                domainName: pointer.domainName,
              );
        }
      }

      final recordGroups = await Future.wait(
        pointers.values.take(48).map((pointer) async {
          final records = await client
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(pointer.domainName),
                timeout: queryTimeout,
              )
              .toList();
          return records
              .map((record) => _DiscoveredService(pointer, record))
              .toList();
        }),
      );
      final services = recordGroups.expand((group) => group).take(64).toList();
      final addressGroups = await Future.wait(
        services.map(
          (service) => client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(service.record.target),
                timeout: queryTimeout,
              )
              .toList(),
        ),
      );

      final observations = <String, DeviceObservation>{};
      for (var index = 0; index < services.length; index++) {
        if (cancellationToken.isCancelled) {
          break;
        }
        final service = services[index];
        for (final addressRecord in addressGroups[index]) {
          final ipAddress = addressRecord.address.address;
          if (!_isAllowed(ipAddress, plan)) {
            continue;
          }
          final observation = _observation(
            ipAddress: ipAddress,
            pointer: service.pointer,
            record: service.record,
          );
          final existing = observations[ipAddress];
          observations[ipAddress] = existing == null
              ? observation
              : const DeviceObservationMerger().merge(existing, observation);
        }
      }
      return List.unmodifiable(observations.values);
    } finally {
      if (started) {
        client.stop();
      }
    }
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
  }) {
    final serviceLabel = '${pointer.serviceType} (${record.port})';
    return DeviceObservation(
      id: 'device-$ipAddress',
      ipAddress: ipAddress,
      displayName: _instanceName(pointer.domainName, pointer.serviceType),
      macStatus: MacStatus.notObserved,
      services: [serviceLabel],
      discoveryMethod: 'mDNS',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.mdns,
          description: 'mDNS servis duyurusu: $serviceLabel',
          serviceType: pointer.serviceType,
          port: record.port,
          identifier: pointer.domainName,
        ),
      ],
    );
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

class _ServicePointer {
  const _ServicePointer({required this.serviceType, required this.domainName});

  final String serviceType;
  final String domainName;
}

class _DiscoveredService {
  const _DiscoveredService(this.pointer, this.record);

  final _ServicePointer pointer;
  final SrvResourceRecord record;
}
