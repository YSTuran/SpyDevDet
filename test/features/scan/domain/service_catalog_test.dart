import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_classifier.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/service_catalog.dart';

void main() {
  const catalog = ServiceCatalog();

  test('yalnız bağlantı kabul eden TCP portunu servis olarak yorumlar', () {
    const device = DeviceObservation(
      id: 'camera',
      ipAddress: '192.168.1.40',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: ['RTSP (554)'],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.tcp,
          description: 'TCP 554 portu bağlantı kabul etti',
          port: 554,
        ),
        DeviceEvidence(
          source: DeviceEvidenceSource.tcp,
          description: 'TCP 80 portu bağlantıyı reddetti; cihaz yanıt verdi',
          port: 80,
        ),
      ],
    );

    final insights = catalog.inspect(device);

    expect(
      insights.map((item) => item.kind),
      contains(ServiceKind.mediaStream),
    );
    expect(insights.map((item) => item.id), isNot(contains('tcp-80')));
  });

  test('ONVIF video duyurusunu yüksek güvenli kamera adayı yapar', () {
    const device = DeviceObservation(
      id: 'camera',
      ipAddress: '192.168.1.40',
      displayName: 'Salon Kamera',
      macStatus: MacStatus.notObserved,
      services: ['ONVIF WS-Discovery'],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.onvif,
          description: 'ONVIF NetworkVideoTransmitter duyurusu',
          serviceType: 'dn:NetworkVideoTransmitter',
          identifier: 'urn:uuid:camera-1',
        ),
      ],
    );

    final result = const DeviceClassifier().classify(device, gatewayIpv4: null);

    expect(result.category, DeviceCategory.cameraCandidate);
    expect(result.confidence, ConfidenceLevel.high);
    expect(catalog.inspect(device).single.kind, ServiceKind.onvifVideo);
  });

  test(
    'Windows servislerini açıklayıp bilgisayar adayı olarak sınıflandırır',
    () {
      const device = DeviceObservation(
        id: 'windows-pc',
        ipAddress: '192.168.1.20',
        displayName: 'Ağ cihazı',
        macStatus: MacStatus.notObserved,
        services: ['SMB/Windows paylaşımı (445)', 'Uzak Masaüstü (3389)'],
        evidence: [
          DeviceEvidence(
            source: DeviceEvidenceSource.tcp,
            description: 'TCP 445 portu bağlantı kabul etti',
            port: 445,
          ),
          DeviceEvidence(
            source: DeviceEvidenceSource.tcp,
            description: 'TCP 3389 portu bağlantı kabul etti',
            port: 3389,
          ),
        ],
      );

      final insights = catalog.inspect(device);
      final classified = const DeviceClassifier().classify(
        device,
        gatewayIpv4: null,
      );

      expect(
        insights.map((item) => item.id),
        containsAll(['tcp-445', 'tcp-3389']),
      );
      expect(classified.category, DeviceCategory.computerOrPhone);
      expect(classified.confidence, ConfidenceLevel.medium);
    },
  );

  test('genel WS-Discovery yanıtını ONVIF kamera olarak etiketlemez', () {
    const device = DeviceObservation(
      id: 'windows-service',
      ipAddress: '192.168.1.30',
      displayName: 'WS-Discovery cihazı',
      macStatus: MacStatus.notObserved,
      services: ['WS-Discovery wsdp:Device'],
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.onvif,
          description: 'Genel WS-Discovery cihaz duyurusu',
          serviceType: 'wsdp:Device',
          identifier: 'urn:uuid:device-1',
        ),
      ],
    );

    final insights = catalog.inspect(device);
    final classified = const DeviceClassifier().classify(
      device,
      gatewayIpv4: null,
    );

    expect(insights.single.id, 'ws-discovery');
    expect(insights.single.kind, ServiceKind.discovery);
    expect(classified.category, DeviceCategory.unknown);
  });
}
