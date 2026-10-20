import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_attention.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

void main() {
  const evaluator = DeviceAttentionEvaluator();

  test('yerel cihazı olağan bulgu olarak değerlendirir', () {
    const device = DeviceObservation(
      id: 'self',
      ipAddress: '192.168.1.20',
      displayName: 'Bu cihaz',
      macStatus: MacStatus.notObserved,
      services: [],
      familiarity: DeviceFamiliarity.newDevice,
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.network,
          description: 'Taramanın çalıştığı cihaz',
        ),
      ],
    );

    expect(evaluator.evaluate(device).level, AttentionLevel.normal);
  });

  test('yeni ve IP tabanlı cihazı yalnız bilgi amaçlı işaretler', () {
    const device = DeviceObservation(
      id: 'device',
      ipAddress: '192.168.1.30',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: [],
      stableKey: 'network:home|ip:192.168.1.30',
      familiarity: DeviceFamiliarity.newDevice,
    );

    final assessment = evaluator.evaluate(device);

    expect(assessment.level, AttentionLevel.informational);
    expect(assessment.score, 2);
  });

  test(
    'yüksek güvenli kamera adayını incelenmesi önerilir olarak gösterir',
    () {
      const device = DeviceObservation(
        id: 'camera',
        ipAddress: '192.168.1.40',
        displayName: 'Kamera adayı',
        macStatus: MacStatus.notObserved,
        services: ['RTSP (554)', '_rtsp._tcp.local (554)'],
        category: DeviceCategory.cameraCandidate,
        confidence: ConfidenceLevel.high,
      );

      expect(evaluator.evaluate(device).level, AttentionLevel.review);
    },
  );

  test(
    'kategori düzeltmesini puan hesabında kullanır ve faktörleri açıklar',
    () {
      const device = DeviceObservation(
        id: 'corrected',
        ipAddress: '192.168.1.40',
        displayName: 'Yanlış sınıflandırılan cihaz',
        macStatus: MacStatus.notObserved,
        services: ['RTSP (554)'],
        category: DeviceCategory.cameraCandidate,
        categoryOverride: DeviceCategory.mediaDevice,
        confidence: ConfidenceLevel.high,
      );

      final assessment = evaluator.evaluate(device);

      expect(assessment.level, AttentionLevel.normal);
      expect(assessment.score, 0);
      expect(assessment.factors.single.points, 0);
    },
  );
}
