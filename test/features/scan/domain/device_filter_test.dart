import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_filter.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

void main() {
  const filter = DeviceListFilter();
  const devices = [
    DeviceObservation(
      id: 'known',
      ipAddress: '192.168.1.20',
      displayName: 'Telefon',
      customName: 'Yusuf telefonu',
      macAddress: 'B8:27:EB:12:34:56',
      macStatus: MacStatus.available,
      vendor: 'Örnek üretici',
      services: ['HTTPS (443)'],
      familiarity: DeviceFamiliarity.known,
      category: DeviceCategory.computerOrPhone,
    ),
    DeviceObservation(
      id: 'camera',
      ipAddress: '192.168.1.5',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: ['RTSP (554)'],
      familiarity: DeviceFamiliarity.newDevice,
      category: DeviceCategory.unknown,
      categoryOverride: DeviceCategory.cameraCandidate,
      confidence: ConfidenceLevel.medium,
    ),
  ];

  test('ad, üretici ve servis alanlarında arar', () {
    expect(filter.apply(devices, query: 'Yusuf').single.id, 'known');
    expect(filter.apply(devices, query: 'üretici').single.id, 'known');
    expect(filter.apply(devices, query: 'rtsp').single.id, 'camera');
  });

  test('kullanıcı kategori düzeltmesini filtrelemede kullanır', () {
    final result = filter.apply(
      devices,
      filter: DeviceFilterOption.cameraCandidates,
    );

    expect(result.map((device) => device.id), ['camera']);
  });

  test('IP adreslerini sayısal sıraya dizer', () {
    final result = filter.apply(devices);

    expect(result.map((device) => device.ipAddress), [
      '192.168.1.5',
      '192.168.1.20',
    ]);
  });
}
