import 'package:spy_dev_det/features/scan/domain/discovery_coverage_advisor.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

enum ScanQualityLevel { comprehensive, limited, insufficient }

extension ScanQualityLevelText on ScanQualityLevel {
  String get label => switch (this) {
    ScanQualityLevel.comprehensive => 'Tam kapsamlı',
    ScanQualityLevel.limited => 'Sınırlı kapsamlı',
    ScanQualityLevel.insufficient => 'Karşılaştırmaya uygun değil',
  };

  String get description => switch (this) {
    ScanQualityLevel.comprehensive => 'Ayrıntılı keşif yöntemleri karşılaştırma için yeterli kapsamla tamamlandı.',
    ScanQualityLevel.limited =>
      'Kullanılabilir sonuçlar var ancak bütün keşif yöntemleri çalışmadı.',
    ScanQualityLevel.insufficient =>
      'Cihaz varlığı hakkında güvenilir karşılaştırma yapacak kapsam oluşmadı.',
  };
}

class ScanQualityAssessment {
  const ScanQualityAssessment({
    required this.level,
    required this.isPresenceComparable,
    required this.reasons,
  });

  final ScanQualityLevel level;
  final bool isPresenceComparable;
  final List<String> reasons;
}

class ScanQualityEvaluator {
  const ScanQualityEvaluator({
    this.coverageAdvisor = const DiscoveryCoverageAdvisor(),
  });

  final DiscoveryCoverageAdvisor coverageAdvisor;

  ScanQualityAssessment evaluateReport(
    ScanReport report, {
    bool rangeTruncated = false,
    bool noDevicesObserved = false,
    bool hasMissingDevices = false,
  }) {
    return evaluate(
      scanMode: report.scanMode,
      methods: report.methods,
      isPartial: report.isPartial,
      isPresenceComparable: report.canComparePresence,
      rangeTruncated: rangeTruncated,
      noDevicesObserved: noDevicesObserved,
      hasMissingDevices: hasMissingDevices,
    );
  }

  ScanQualityAssessment evaluate({
    required ScanMode scanMode,
    required Map<DiscoveryMethod, DiscoveryMethodResult> methods,
    required bool isPartial,
    required bool isPresenceComparable,
    bool rangeTruncated = false,
    bool noDevicesObserved = false,
    bool hasMissingDevices = false,
  }) {
    final reasons = <String>[];
    if (scanMode == ScanMode.quick) {
      reasons.add(
        'Hızlı mod servis duyurularının tamamını çalıştırmadığı için referans '
        'karşılaştırmasına uygun değildir.',
      );
    }
    reasons.addAll(
      coverageAdvisor.explain(
        methods: methods,
        rangeTruncated: rangeTruncated,
        noDevicesObserved: noDevicesObserved,
        hasMissingDevices: hasMissingDevices,
      ),
    );

    final hasUsableDiscovery = methods.values.any(
      (result) =>
          result.phase == DiscoveryMethodPhase.completed ||
          result.phase == DiscoveryMethodPhase.platformRestricted,
    );
    final comparable = isPresenceComparable && !rangeTruncated;
    final level = comparable
        ? ScanQualityLevel.comprehensive
        : hasUsableDiscovery && (!isPartial || _hasPresenceSignal(methods))
        ? ScanQualityLevel.limited
        : ScanQualityLevel.insufficient;

    if (level == ScanQualityLevel.comprehensive && reasons.isEmpty) {
      reasons.add(
        'Bütün gerekli keşif yöntemleri tamamlandı; Android komşu tablosu '
        'kısıtı varsa bu beklenen platform davranışı olarak kabul edildi.',
      );
    }
    if (level == ScanQualityLevel.insufficient && reasons.isEmpty) {
      reasons.add('Yeterli bir cihaz varlığı sinyali alınamadı.');
    }

    return ScanQualityAssessment(
      level: level,
      isPresenceComparable: comparable,
      reasons: List.unmodifiable(reasons.toSet()),
    );
  }

  bool _hasPresenceSignal(
    Map<DiscoveryMethod, DiscoveryMethodResult> methods,
  ) => const [
    DiscoveryMethod.reachability,
    DiscoveryMethod.neighbor,
  ].any((method) => methods[method]?.phase == DiscoveryMethodPhase.completed);
}
