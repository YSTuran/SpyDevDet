import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_classifier.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

void main() {
  const classifier = DeviceClassifier();

  test('taramayı çalıştıran cihaz yüksek güvenle telefon olarak tanınır', () {
    const device = DeviceObservation(
      id: 'device-local',
      ipAddress: '192.168.1.2',
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

    final result = classifier.classify(device, gatewayIpv4: '192.168.1.1');

    expect(result.category, DeviceCategory.computerOrPhone);
    expect(result.confidence, ConfidenceLevel.high);
  });

  test('ağ geçidi yüksek güvenle yönlendirici olarak sınıflandırılır', () {
    const device = DeviceObservation(
      id: 'device-1',
      ipAddress: '192.168.1.1',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: [],
    );

    final result = classifier.classify(device, gatewayIpv4: '192.168.1.1');

    expect(result.category, DeviceCategory.router);
    expect(result.confidence, ConfidenceLevel.high);
    expect(
      result.evidence.any(
        (item) => item.source == DeviceEvidenceSource.network,
      ),
      isTrue,
    );
  });

  test('yalnız RTSP gözlemi düşük güvenli kamera adayı üretir', () {
    const device = DeviceObservation(
      id: 'device-2',
      ipAddress: '192.168.1.8',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: ['RTSP (554)'],
    );

    final result = classifier.classify(device, gatewayIpv4: null);

    expect(result.category, DeviceCategory.cameraCandidate);
    expect(result.confidence, ConfidenceLevel.low);
  });

  test('IPP duyurusu yüksek güvenli yazıcı adayı üretir', () {
    const device = DeviceObservation(
      id: 'device-3',
      ipAddress: '192.168.1.9',
      displayName: 'Ofis yazıcısı',
      macStatus: MacStatus.notObserved,
      services: ['_ipp._tcp.local (631)'],
    );

    final result = classifier.classify(device, gatewayIpv4: null);

    expect(result.category, DeviceCategory.printer);
    expect(result.confidence, ConfidenceLevel.high);
  });
}
