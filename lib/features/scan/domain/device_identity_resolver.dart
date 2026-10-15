import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/mac_address.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

class DeviceIdentityResolver {
  const DeviceIdentityResolver();

  String resolve(DeviceObservation device, {required String networkKey}) {
    final rawMac = device.macAddress;
    if (rawMac != null) {
      final mac = MacAddress.tryParse(rawMac);
      if (mac != null && !mac.isLocallyAdministered) {
        return 'mac:${mac.value}';
      }
    }

    final ssdpIdentifier = _identifierFor(device, DeviceEvidenceSource.ssdp);
    if (ssdpIdentifier != null) {
      return 'ssdp:$ssdpIdentifier';
    }

    final mdnsIdentifier = _identifierFor(device, DeviceEvidenceSource.mdns);
    if (mdnsIdentifier != null) {
      return 'mdns:$mdnsIdentifier';
    }

    return 'network:$networkKey|ip:${device.ipAddress}';
  }

  String networkKey(ScanPlan plan) =>
      '${plan.networkAddress}/${plan.network.prefixLength}|'
      'gateway:${plan.network.gatewayIpv4 ?? '-'}';

  String? _identifierFor(
    DeviceObservation device,
    DeviceEvidenceSource source,
  ) {
    for (final evidence in device.evidence) {
      final identifier = evidence.identifier?.trim().toLowerCase();
      if (evidence.source == source &&
          identifier != null &&
          identifier.isNotEmpty) {
        return identifier.length <= 256
            ? identifier
            : identifier.substring(0, 256);
      }
    }
    return null;
  }
}
