import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/history/domain/scan_report_export.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  const exporter = ScanReportExporter();

  test('gizlilik korumalı JSON özel ağ verilerini sızdırmaz', () {
    final report = exporter.generate(
      details: _details(),
      format: ScanReportExportFormat.json,
      privacyMode: ScanReportPrivacyMode.masked,
      applicationVersion: '2.1.0',
    );

    expect(report.content, isNot(contains('Salon kamerası')));
    expect(report.content, isNot(contains('192.168.1.42')));
    expect(report.content, isNot(contains('B8:27:EB:12:34:56')));
    expect(report.content, isNot(contains('Özel kullanıcı notu')));
    expect(report.content, contains('192.168.1.x'));
    final decoded = jsonDecode(report.content) as Map<String, dynamic>;
    expect(decoded['schemaVersion'], 1);
    expect(decoded['privacyMode'], 'masked');
  });

  test('tam teknik JSON seçildiğinde cihaz ayrıntılarını içerir', () {
    final report = exporter.generate(
      details: _details(),
      format: ScanReportExportFormat.json,
      privacyMode: ScanReportPrivacyMode.full,
      applicationVersion: '2.1.0',
    );

    expect(report.content, contains('Salon kamerası'));
    expect(report.content, contains('192.168.1.42'));
    expect(report.content, contains('B8:27:EB:12:34:56'));
    expect(report.content, contains('Özel kullanıcı notu'));
  });

  test('CSV özel karakterleri güvenli biçimde kaçışlar', () {
    final report = exporter.generate(
      details: _details(displayName: 'Salon, "kamera"'),
      format: ScanReportExportFormat.csv,
      privacyMode: ScanReportPrivacyMode.full,
      applicationVersion: '2.1.0',
    );

    expect(report.content, contains('"Salon, ""kamera"""'));
  });
}

ScanHistoryDetails _details({String displayName = 'Salon kamerası'}) {
  final completedAt = DateTime(2026, 10, 22, 10, 0, 2);
  final methods = {
    for (final method in DiscoveryMethod.values)
      method: DiscoveryMethodResult(
        method: method,
        phase: DiscoveryMethodPhase.completed,
      ),
  };
  return ScanHistoryDetails(
    summary: ScanHistorySummary(
      id: 4,
      networkKey:
          '192.168.1.0/24|gateway:192.168.1.1|gateway-mac:AA:BB:CC:DD:EE:FF',
      startedAt: completedAt.subtract(const Duration(seconds: 2)),
      completedAt: completedAt,
      isPartial: false,
      totalDeviceCount: 1,
      newDeviceCount: 1,
      missingDevices: const [],
      elapsed: const Duration(seconds: 2),
      methods: methods,
      isPresenceComparable: true,
      scanMode: ScanMode.detailed,
    ),
    devices: [
      DeviceObservation(
        id: 'device',
        stableKey: 'mac:B8:27:EB:12:34:56',
        ipAddress: '192.168.1.42',
        displayName: displayName,
        customName: displayName,
        macAddress: 'B8:27:EB:12:34:56',
        macStatus: MacStatus.available,
        vendor: 'Raspberry Pi Foundation',
        services: const ['RTSP (554)'],
        note: 'Özel kullanıcı notu',
        category: DeviceCategory.cameraCandidate,
        confidence: ConfidenceLevel.high,
        evidence: const [
          DeviceEvidence(
            source: DeviceEvidenceSource.onvif,
            description: 'ONVIF cihaz duyurusu',
            identifier: 'urn:uuid:secret-device',
          ),
        ],
      ),
    ],
  );
}
