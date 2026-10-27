import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/discovery_coverage_advisor.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  const advisor = DiscoveryCoverageAdvisor();

  test('hızlı taramada atlanan servis keşiflerini açıklar', () {
    final methods = {
      for (final method in DiscoveryMethod.values)
        method: DiscoveryMethodResult(
          method: method,
          phase:
              const {
                DiscoveryMethod.mdns,
                DiscoveryMethod.ssdp,
                DiscoveryMethod.onvif,
                DiscoveryMethod.netbios,
              }.contains(method)
              ? DiscoveryMethodPhase.skipped
              : DiscoveryMethodPhase.completed,
        ),
    };

    final explanations = advisor.explain(methods: methods);

    expect(
      explanations,
      contains(contains('Hızlı taramada yerel servis duyuruları')),
    );
  });

  test('kapsama sorunlarını olasılık diliyle açıklar', () {
    final methods = {
      for (final method in DiscoveryMethod.values)
        method: DiscoveryMethodResult(
          method: method,
          phase: method == DiscoveryMethod.neighbor
              ? DiscoveryMethodPhase.unavailable
              : DiscoveryMethodPhase.completed,
        ),
    };

    final explanations = advisor.explain(
      methods: methods,
      rangeTruncated: true,
      hasMissingDevices: true,
    );

    expect(explanations, hasLength(3));
    expect(explanations.join(' '), contains('olabilir'));
    expect(explanations.join(' '), contains('MAC ve üretici'));
  });

  test('Android platform kısıtının açıklamasını korur', () {
    final methods = {
      for (final method in DiscoveryMethod.values)
        method: DiscoveryMethodResult(
          method: method,
          phase: method == DiscoveryMethod.neighbor
              ? DiscoveryMethodPhase.platformRestricted
              : DiscoveryMethodPhase.completed,
          userMessage: method == DiscoveryMethod.neighbor
              ? 'Android komşu MAC tablosunu gizler.'
              : null,
        ),
    };

    final explanations = advisor.explain(methods: methods);

    expect(explanations, contains('Android komşu MAC tablosunu gizler.'));
  });
}
