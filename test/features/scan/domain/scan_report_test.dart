import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  test('yöntem sonucunu günceller ve kısmi taramayı belirler', () {
    final report = ScanReport.started(DateTime(2026, 10, 15)).withMethod(
      const DiscoveryMethodResult(
        method: DiscoveryMethod.mdns,
        phase: DiscoveryMethodPhase.unavailable,
        userMessage: 'Kullanılamıyor',
      ),
    );

    expect(
      report.methods[DiscoveryMethod.mdns]?.phase,
      DiscoveryMethodPhase.unavailable,
    );
    expect(report.isPartial, isTrue);
  });

  test('çalışan yöntemleri iptal edildi olarak işaretler', () {
    final report = ScanReport.started(DateTime(2026, 10, 15)).withMethod(
      const DiscoveryMethodResult(
        method: DiscoveryMethod.tcp,
        phase: DiscoveryMethodPhase.running,
      ),
    );

    final cancelled = report.cancelRunning();

    expect(
      cancelled.methods[DiscoveryMethod.tcp]?.phase,
      DiscoveryMethodPhase.cancelled,
    );
  });

  test(
    'karşılaştırma için bütün ayrıntılı yöntemlerin tamamlanmasını ister',
    () {
      var report = ScanReport.started(DateTime(2026, 10, 15));
      for (final method in const [
        DiscoveryMethod.tcp,
        DiscoveryMethod.mdns,
        DiscoveryMethod.ssdp,
        DiscoveryMethod.onvif,
      ]) {
        report = report.withMethod(
          DiscoveryMethodResult(
            method: method,
            phase: DiscoveryMethodPhase.completed,
          ),
        );
      }

      expect(report.canComparePresence, isFalse);

      report = report.withMethod(
        const DiscoveryMethodResult(
          method: DiscoveryMethod.reachability,
          phase: DiscoveryMethodPhase.completed,
        ),
      );

      expect(report.canComparePresence, isFalse);

      report = report
          .withMethod(
            const DiscoveryMethodResult(
              method: DiscoveryMethod.reachability,
              phase: DiscoveryMethodPhase.completed,
            ),
          )
          .withMethod(
            const DiscoveryMethodResult(
              method: DiscoveryMethod.neighbor,
              phase: DiscoveryMethodPhase.completed,
            ),
          );

      expect(report.canComparePresence, isTrue);
      expect(report.isPartial, isFalse);
    },
  );

  test('hızlı tarama atlanan yöntemlerle tamamlanır ama kıyaslanmaz', () {
    var report = ScanReport.started(
      DateTime(2026, 10, 15),
      scanMode: ScanMode.quick,
    );
    for (final method in DiscoveryMethod.values) {
      report = report.withMethod(
        DiscoveryMethodResult(
          method: method,
          phase:
              const {
                DiscoveryMethod.mdns,
                DiscoveryMethod.ssdp,
                DiscoveryMethod.onvif,
              }.contains(method)
              ? DiscoveryMethodPhase.skipped
              : DiscoveryMethodPhase.completed,
        ),
      );
    }

    expect(report.isPartial, isFalse);
    expect(report.canComparePresence, isFalse);
    expect(report.scanMode, ScanMode.quick);
  });
}
