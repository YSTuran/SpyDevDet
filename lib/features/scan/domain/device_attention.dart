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
    required this.reasons,
  });

  final AttentionLevel level;
  final int score;
  final List<String> reasons;
}

class DeviceAttentionEvaluator {
  const DeviceAttentionEvaluator();

  DeviceAttentionAssessment evaluate(DeviceObservation device) {
    if (_isLocalDevice(device)) {
      return const DeviceAttentionAssessment(
        level: AttentionLevel.normal,
        score: 0,
        reasons: ['Taramanın çalıştığı cihaz'],
      );
    }

    var score = 0;
    final reasons = <String>[];
    if (device.familiarity == DeviceFamiliarity.newDevice) {
      score += 1;
      reasons.add('Bu ağın kayıtlı geçmişinde ilk kez görüldü');
    }
    if (device.category == DeviceCategory.cameraCandidate) {
      final points = device.confidence == ConfidenceLevel.high ? 3 : 2;
      score += points;
      reasons.add(
        device.confidence == ConfidenceLevel.high
            ? 'Birden fazla ağ bulgusu kamera servisleriyle eşleşti'
            : 'RTSP veya kamera kimliğiyle ilişkili bir ağ bulgusu gözlemlendi',
      );
    }
    if (device.stableKey?.startsWith('network:') == true) {
      score += 1;
      reasons.add('Kalıcı kimlik bulunamadığı için eşleşme ağ ve IP tabanlı');
    }

    final level = switch (score) {
      >= 3 => AttentionLevel.review,
      > 0 => AttentionLevel.informational,
      _ => AttentionLevel.normal,
    };
    return DeviceAttentionAssessment(
      level: level,
      score: score,
      reasons: List.unmodifiable(
        reasons.isEmpty ? const ['Ek inceleme gerektiren bulgu yok'] : reasons,
      ),
    );
  }

  bool _isLocalDevice(DeviceObservation device) => device.evidence.any(
    (item) =>
        item.source == DeviceEvidenceSource.network &&
        item.description == 'Taramanın çalıştığı cihaz',
  );
}
