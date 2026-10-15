import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation_merger.dart';

void main() {
  test('aynı IP için farklı keşif kanıtlarını kaybetmeden birleştirir', () {
    const tcp = DeviceObservation(
      id: 'tcp-device',
      ipAddress: '192.168.1.20',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: ['HTTP (80)'],
      discoveryMethod: 'TCP bağlantı denemesi',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.tcp,
          description: 'TCP 80 portu bağlantı kabul etti',
          port: 80,
        ),
      ],
    );
    const mdns = DeviceObservation(
      id: 'mdns-device',
      ipAddress: '192.168.1.20',
      displayName: 'Salon cihazı',
      macStatus: MacStatus.notObserved,
      services: ['_googlecast._tcp.local (8009)'],
      discoveryMethod: 'mDNS',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.mdns,
          description: 'mDNS servis duyurusu',
        ),
      ],
    );

    final result = const DeviceObservationMerger().merge(tcp, mdns);

    expect(result.displayName, 'Salon cihazı');
    expect(result.services, hasLength(2));
    expect(result.evidence, hasLength(2));
    expect(result.discoveryMethod, contains('TCP bağlantı denemesi'));
    expect(result.discoveryMethod, contains('mDNS'));
  });
}
