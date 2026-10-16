import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_identity_resolver.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

void main() {
  test('yerel cihazın kimliği DHCP adresinden bağımsızdır', () {
    const resolver = DeviceIdentityResolver();
    const device = DeviceObservation(
      id: 'self',
      ipAddress: '192.168.1.24',
      displayName: 'Bu cihaz',
      macStatus: MacStatus.notObserved,
      services: [],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.network,
          description: 'Taramanın çalıştığı cihaz',
        ),
      ],
    );

    expect(
      resolver.resolve(device, networkKey: '192.168.1.0/24'),
      'local:this-installation',
    );
  });

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

  test('mDNS kimliğini yalnız mevcut ağ içinde kullanır', () {
    const resolver = DeviceIdentityResolver();
    const device = DeviceObservation(
      id: 'mdns-device',
      ipAddress: '192.168.1.30',
      displayName: 'Salon',
      macStatus: MacStatus.notObserved,
      services: [],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.mdns,
          description: 'mDNS servis duyurusu',
          identifier: 'Salon._airplay._tcp.local',
        ),
      ],
    );

    expect(
      resolver.resolve(device, networkKey: '192.168.1.0/24'),
      'mdns:192.168.1.0/24|salon._airplay._tcp.local',
    );
  });

  test('ONVIF endpoint kimliğini SSDP kimliğine tercih eder', () {
    const device = DeviceObservation(
      id: 'device-onvif',
      ipAddress: '192.168.1.40',
      displayName: 'ONVIF cihazı',
      macStatus: MacStatus.notObserved,
      services: [],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.ssdp,
          description: 'SSDP duyurusu',
          identifier: 'uuid:ssdp-device',
        ),
        DeviceEvidence(
          source: DeviceEvidenceSource.onvif,
          description: 'ONVIF duyurusu',
          identifier: 'urn:uuid:onvif-device',
        ),
      ],
    );

    expect(
      resolver.resolve(device, networkKey: '192.168.1.0/24'),
      'onvif:urn:uuid:onvif-device',
    );
  });
}
