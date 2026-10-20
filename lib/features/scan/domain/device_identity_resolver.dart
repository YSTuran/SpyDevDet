import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/mac_address.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

class DeviceIdentityResolver {
  const DeviceIdentityResolver();

  String resolve(DeviceObservation device, {required String networkKey}) =>
      candidateKeys(device, networkKey: networkKey).first;

  List<String> candidateKeys(
    DeviceObservation device, {
    required String networkKey,
  }) {
    final isLocalDevice = device.evidence.any(
      (item) =>
          item.source == DeviceEvidenceSource.network &&
          item.description == 'Taramanın çalıştığı cihaz',
    );
    if (isLocalDevice) {
      // The database is local to this installation, so this reserved key stays
      // stable when DHCP changes the phone or computer's local IP address.
      return const ['local:this-installation'];
    }

    final keys = <String>{};
    final rawMac = device.macAddress;
    if (rawMac != null) {
      final mac = MacAddress.tryParse(rawMac);
      if (mac != null && !mac.isLocallyAdministered) {
        keys.add('mac:${mac.value}');
      }
    }

    final ssdpIdentifier = _identifierFor(device, DeviceEvidenceSource.ssdp);
    final onvifIdentifier = _identifierFor(device, DeviceEvidenceSource.onvif);
    if (onvifIdentifier != null) {
      keys.add('onvif:$onvifIdentifier');
    }
    if (ssdpIdentifier != null) {
      keys.add('ssdp:$ssdpIdentifier');
    }

    final mdnsIdentifier = _identifierFor(device, DeviceEvidenceSource.mdns);
    if (mdnsIdentifier != null) {
      // mDNS instance names are not globally unique and can repeat on another
      // home network, so keep this weaker identity scoped to the network.
      keys.add('mdns:$networkKey|$mdnsIdentifier');
    }

    keys.add('network:$networkKey|ip:${device.ipAddress}');
    return List.unmodifiable(keys);
  }

  String networkKey(ScanPlan plan) =>
      '${plan.networkAddress}/${plan.network.prefixLength}|'
      'gateway:${plan.network.gatewayIpv4 ?? '-'}';

  List<String> networkIdentityKeys(
    ScanPlan plan, {
    String? gatewayMacAddress,
    String? gatewayServiceIdentity,
  }) {
    final baseKey = networkKey(plan);
    final gatewayMac = gatewayMacAddress == null
        ? null
        : MacAddress.tryParse(gatewayMacAddress);
    final serviceIdentity = gatewayServiceIdentity?.trim().toLowerCase();
    final boundedServiceIdentity = serviceIdentity == null
        ? null
        : serviceIdentity.length <= 256
        ? serviceIdentity
        : serviceIdentity.substring(0, 256);
    return List.unmodifiable([
      if (gatewayMac != null) '$baseKey|gateway-mac:${gatewayMac.value}',
      if (boundedServiceIdentity != null && boundedServiceIdentity.isNotEmpty)
        '$baseKey|gateway-service:'
            '${Uri.encodeComponent(boundedServiceIdentity)}',
      baseKey,
    ]);
  }

  String? gatewayServiceIdentity(DeviceObservation? gateway) {
    if (gateway == null) {
      return null;
    }
    for (final source in const [
      DeviceEvidenceSource.onvif,
      DeviceEvidenceSource.ssdp,
    ]) {
      final identifier = _identifierFor(gateway, source);
      if (identifier != null) {
        return '${source.name}:$identifier';
      }
    }
    return null;
  }

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
