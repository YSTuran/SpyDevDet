import 'package:flutter_test/flutter_test.dart';
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
}
