import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/domain/reference_scan_comparison.dart';
import 'package:spy_dev_det/features/history/presentation/reference_comparison_card.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';

void main() {
  testWidgets('referans farklarının üç grubunu kullanıcıya gösterir', (
    tester,
  ) async {
    final comparison = ReferenceScanComparison.available(
      baselineSessionId: 1,
      baselineCompletedAt: DateTime(2026, 10, 20, 10),
      usesExplicitReference: true,
      addedDevices: const [
        ComparedDeviceSummary(
          stableKey: 'added',
          displayName: 'Yeni cihaz',
          ipAddress: '192.168.1.40',
          category: DeviceCategory.unknown,
        ),
      ],
      missingDevices: const [
        ComparedDeviceSummary(
          stableKey: 'missing',
          displayName: 'Görülmeyen cihaz',
          ipAddress: '192.168.1.30',
          category: DeviceCategory.mediaDevice,
        ),
      ],
      changedDevices: const [
        ReferenceDeviceChange(
          device: ComparedDeviceSummary(
            stableKey: 'changed',
            displayName: 'Değişen cihaz',
            ipAddress: '192.168.1.25',
            category: DeviceCategory.cameraCandidate,
          ),
          previousIpAddress: '192.168.1.20',
          currentIpAddress: '192.168.1.25',
          addedServices: ['RTSP (554)'],
          removedServices: [],
          previousVendor: null,
          currentVendor: null,
          previousCategory: DeviceCategory.unknown,
          currentCategory: DeviceCategory.cameraCandidate,
          previousConfidence: ConfidenceLevel.low,
          currentConfidence: ConfidenceLevel.high,
          previousIdentityQuality: ObservedIdentityQuality.strong,
          currentIdentityQuality: ObservedIdentityQuality.strong,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReferenceComparisonCard(comparison: comparison),
          ),
        ),
      ),
    );

    expect(find.text('Seçili ağ referansı: 20.10.2026 10:00'), findsOneWidget);
    expect(find.text('1 eklendi'), findsOneWidget);
    expect(find.text('1 görülmedi'), findsOneWidget);
    expect(find.text('1 değişti'), findsOneWidget);
    expect(find.text('Yeni cihaz'), findsOneWidget);
    expect(find.text('Görülmeyen cihaz'), findsOneWidget);
    expect(find.text('Değişen cihaz'), findsOneWidget);
  });
}
