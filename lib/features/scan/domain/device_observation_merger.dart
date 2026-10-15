import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

class DeviceObservationMerger {
  const DeviceObservationMerger();

  DeviceObservation merge(
    DeviceObservation current,
    DeviceObservation incoming,
  ) {
    if (current.ipAddress != incoming.ipAddress) {
      throw ArgumentError(
        'Yalnızca aynı IP adresine ait gözlemler birleştirilebilir.',
      );
    }

    final services = {...current.services, ...incoming.services}.toList()
      ..sort();
    final evidenceById = <String, DeviceEvidence>{
      for (final item in current.evidence) item.identity: item,
      for (final item in incoming.evidence) item.identity: item,
    };
    final methods = <String>{
      ..._methods(current.discoveryMethod),
      ..._methods(incoming.discoveryMethod),
    };
    final incomingHasMac = incoming.macStatus == MacStatus.available;

    return DeviceObservation(
      id: 'device-${current.ipAddress}',
      ipAddress: current.ipAddress,
      displayName: _preferredName(current, incoming),
      macAddress: incomingHasMac
          ? incoming.macAddress
          : current.macAddress ?? incoming.macAddress,
      macStatus: incomingHasMac ? incoming.macStatus : current.macStatus,
      vendor: incoming.vendor ?? current.vendor,
      services: List.unmodifiable(services),
      discoveryMethod: methods.join(' + '),
      evidence: List.unmodifiable(evidenceById.values),
      category: incoming.confidence.index >= current.confidence.index
          ? incoming.category
          : current.category,
      confidence: incoming.confidence.index >= current.confidence.index
          ? incoming.confidence
          : current.confidence,
    );
  }

  String _preferredName(DeviceObservation current, DeviceObservation incoming) {
    final currentScore = _nameScore(current.displayName, current.ipAddress);
    final incomingScore = _nameScore(incoming.displayName, incoming.ipAddress);
    return incomingScore > currentScore
        ? incoming.displayName
        : current.displayName;
  }

  int _nameScore(String name, String ipAddress) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty || normalized == ipAddress) {
      return 0;
    }
    if (normalized == 'ağ cihazı' || normalized.endsWith('adayı')) {
      return 1;
    }
    return 2;
  }

  Iterable<String> _methods(String value) => value
      .split(' + ')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != 'Bilinmiyor');
}
