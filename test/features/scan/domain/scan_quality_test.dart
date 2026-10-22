import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_quality.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  const evaluator = ScanQualityEvaluator();

  test('Android komşu tablosu kısıtı tam kapsamı tek başına bozmaz', () {
    final report = _report(
      neighborPhase: DiscoveryMethodPhase.platformRestricted,
    );

    final quality = evaluator.evaluateReport(report);

    expect(quality.level, ScanQualityLevel.comprehensive);
    expect(quality.isPresenceComparable, isTrue);
  });

  test('hızlı taramayı sınırlı kapsamlı olarak açıklar', () {
    final report = _report(scanMode: ScanMode.quick);

    final quality = evaluator.evaluateReport(report);

    expect(quality.level, ScanQualityLevel.limited);
    expect(quality.isPresenceComparable, isFalse);
    expect(quality.reasons.join(' '), contains('Hızlı mod'));
  });

  test('cihaz varlığı sinyali yoksa karşılaştırmaya uygun saymaz', () {
    final report = _report(
      reachabilityPhase: DiscoveryMethodPhase.failed,
      neighborPhase: DiscoveryMethodPhase.platformRestricted,
    );

    final quality = evaluator.evaluateReport(report);

    expect(quality.level, ScanQualityLevel.insufficient);
    expect(quality.isPresenceComparable, isFalse);
  });

  test('kırpılmış aralığı tam kapsamlı saymaz', () {
    final quality = evaluator.evaluateReport(_report(), rangeTruncated: true);

    expect(quality.level, ScanQualityLevel.limited);
    expect(quality.isPresenceComparable, isFalse);
  });
}

ScanReport _report({
  ScanMode scanMode = ScanMode.detailed,
  DiscoveryMethodPhase reachabilityPhase = DiscoveryMethodPhase.completed,
  DiscoveryMethodPhase neighborPhase = DiscoveryMethodPhase.completed,
}) {
  return ScanReport(
    startedAt: DateTime(2026, 10, 22, 10),
    completedAt: DateTime(2026, 10, 22, 10, 0, 2),
    scanMode: scanMode,
    methods: {
      for (final method in DiscoveryMethod.values)
        method: DiscoveryMethodResult(
          method: method,
          phase: method == DiscoveryMethod.reachability
              ? reachabilityPhase
              : method == DiscoveryMethod.neighbor
              ? neighborPhase
              : scanMode == ScanMode.quick
              ? DiscoveryMethodPhase.skipped
              : DiscoveryMethodPhase.completed,
        ),
    },
  );
}
