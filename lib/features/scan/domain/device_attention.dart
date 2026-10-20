import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

enum AttentionLevel { normal, informational, review }

extension AttentionLevelText on AttentionLevel {
  String get label => switch (this) {
    AttentionLevel.normal => 'Olağan bulgu',
    AttentionLevel.informational => 'Bilgi amaçlı incele',
    AttentionLevel.review => 'İncelenmesi önerilir',
  };
}

class DeviceAttentionAssessment {
  const DeviceAttentionAssessment({
    required this.level,
    required this.score,
    required this.factors,
  });

  final AttentionLevel level;
  final int score;
  final List<AttentionFactor> factors;

  List<String> get reasons =>
      List.unmodifiable(factors.map((factor) => factor.description));
}

class AttentionFactor {
  const AttentionFactor({required this.description, required this.points});

  final String description;
  final int points;
}

class DeviceAttentionEvaluator {
  const DeviceAttentionEvaluator();

  DeviceAttentionAssessment evaluate(DeviceObservation device) {
    if (_isLocalDevice(device)) {
      return const DeviceAttentionAssessment(
        level: AttentionLevel.normal,
        score: 0,
        factors: [
          AttentionFactor(description: 'Taramanın çalıştığı cihaz', points: 0),
        ],
      );
    }

    var score = 0;
    final factors = <AttentionFactor>[];
    if (device.familiarity == DeviceFamiliarity.newDevice) {
      score += 1;
      factors.add(
        const AttentionFactor(
          description: 'Bu ağın kayıtlı geçmişinde ilk kez görüldü',
          points: 1,
        ),
      );
    }
    if (device.effectiveCategory == DeviceCategory.cameraCandidate) {
      final points = device.confidence == ConfidenceLevel.high ? 3 : 2;
      score += points;
      factors.add(
        AttentionFactor(
          description: device.confidence == ConfidenceLevel.high
              ? 'Birden fazla ağ bulgusu kamera servisleriyle eşleşti'
              : 'RTSP veya kamera kimliğiyle ilişkili bir ağ bulgusu gözlemlendi',
          points: points,
        ),
      );
    }
    if (device.stableKey?.startsWith('network:') == true) {
      score += 1;
      factors.add(
        const AttentionFactor(
          description:
              'Kalıcı kimlik bulunamadığı için eşleşme ağ ve IP tabanlı',
          points: 1,
        ),
      );
    }

    final level = switch (score) {
      >= 3 => AttentionLevel.review,
      > 0 => AttentionLevel.informational,
      _ => AttentionLevel.normal,
    };
    return DeviceAttentionAssessment(
      level: level,
      score: score,
      factors: List.unmodifiable(
        factors.isEmpty
            ? const [
                AttentionFactor(
                  description: 'Ek inceleme gerektiren bulgu yok',
                  points: 0,
                ),
              ]
            : factors,
      ),
    );
  }

  bool _isLocalDevice(DeviceObservation device) => device.evidence.any(
    (item) =>
        item.source == DeviceEvidenceSource.network &&
        item.description == 'Taramanın çalıştığı cihaz',
  );
}
