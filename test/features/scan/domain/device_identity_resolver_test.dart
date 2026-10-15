import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_identity_resolver.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

void main() {
  const resolver = DeviceIdentityResolver();

  test('genel MAC adresini en güçlü kimlik olarak kullanır', () {
    const device = DeviceObservation(
      id: 'device-1',
      ipAddress: '192.168.1.20',
      displayName: 'Cihaz',
      macAddress: 'B8:27:EB:12:34:56',
      macStatus: MacStatus.available,
      services: [],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.ssdp,
          description: 'SSDP',
          identifier: 'uuid:other',
        ),
      ],
    );

    expect(
      resolver.resolve(device, networkKey: 'network-a'),
      'mac:B8:27:EB:12:34:56',
    );
  });

  test('yerel MAC yerine SSDP kimliğini kullanır', () {
    const device = DeviceObservation(
      id: 'device-2',
      ipAddress: '192.168.1.21',
      displayName: 'Cihaz',
      macAddress: '02:11:22:33:44:55',
      macStatus: MacStatus.available,
      services: [],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.ssdp,
          description: 'SSDP',
          identifier: 'UUID:DEVICE-1',
        ),
      ],
    );

    expect(
      resolver.resolve(device, networkKey: 'network-a'),
      'ssdp:uuid:device-1',
    );
  });

  test('güçlü kimlik yoksa ağ ve IP tabanlı anahtar kullanır', () {
    const device = DeviceObservation(
      id: 'device-3',
      ipAddress: '192.168.1.22',
      displayName: 'Cihaz',
      macStatus: MacStatus.notObserved,
      services: [],
    );

    expect(
      resolver.resolve(device, networkKey: '192.168.1.0/24'),
      'network:192.168.1.0/24|ip:192.168.1.22',
    );
  });
}
