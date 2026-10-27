import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/diagnostic_bundle_export.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  test('tanılama paketi ağ kimliklerini varsayılan olarak maskeleler', () {
    const localIp = '192.168.1.42';
    const gatewayIp = '192.168.1.1';
    const macAddress = 'B8:27:EB:12:34:56';
    final startedAt = DateTime.utc(2026, 10, 27, 8);
    final report = ScanReport(
      startedAt: startedAt,
      completedAt: startedAt.add(const Duration(seconds: 3)),
      scanMode: ScanMode.detailed,
      methods: {
        DiscoveryMethod.tcp: const DiscoveryMethodResult(
          method: DiscoveryMethod.tcp,
          phase: DiscoveryMethodPhase.completed,
          elapsed: Duration(seconds: 2),
          metrics: DiscoveryMetrics(
            attemptedTargets: 10,
            sentRequests: 100,
            detail: 'Yerel hedef 192.168.1.55 yanıt verdi',
          ),
        ),
      },
    );

    final generated = const DiagnosticBundleExporter().generate(
      applicationVersion: '2.4.0+18',
      operatingSystem: 'android',
      operatingSystemVersion: 'Android 11',
      scanPhase: 'completed',
      statusMessage: '$localIp taraması tamamlandı $macAddress',
      scanMode: ScanMode.detailed,
      scannedTargets: 10,
      totalTargets: 10,
      rangeTruncated: false,
      network: const NetworkSnapshot(
        localIpv4: localIp,
        prefixLength: 24,
        interfaceName: 'wlan0',
        gatewayIpv4: gatewayIp,
        isWifi: true,
        isVpn: false,
      ),
      scanRange: '192.168.1.1 - 192.168.1.254',
      report: report,
      generatedAt: DateTime.utc(2026, 10, 27, 9),
    );

    final payload = jsonDecode(generated.content) as Map<String, dynamic>;
    final privacy = payload['privacy'] as Map<String, dynamic>;
    expect(generated.mimeType, 'application/json');
    expect(privacy['automaticUpload'], isFalse);
    expect(generated.content, isNot(contains(localIp)));
    expect(generated.content, isNot(contains(gatewayIp)));
    expect(generated.content, isNot(contains('192.168.1.55')));
    expect(generated.content, isNot(contains(macAddress)));
    expect(generated.content, contains('192.168.1.x'));
    expect(generated.content, contains('DISCOVERY_TCP_COMPLETED'));
  });
}
