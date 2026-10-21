import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/domain/reference_scan_comparison.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

void main() {
  const comparator = ReferenceScanComparator();

  test('eklenen, görülmeyen ve değişen cihazları ayrı gruplar', () {
    final result = comparator.compare(
      baselineSessionId: 7,
      baselineCompletedAt: DateTime(2026, 10, 20, 10),
      usesExplicitReference: true,
      baselineDevices: [
        _device(
          key: 'mac:AA:BB:CC:00:00:01',
          ip: '192.168.1.20',
          services: const ['HTTP (80)'],
        ),
        _device(key: 'mac:AA:BB:CC:00:00:02', ip: '192.168.1.30'),
      ],
      currentDevices: [
        _device(
          key: 'mac:AA:BB:CC:00:00:01',
          ip: '192.168.1.25',
          services: const ['HTTP (80)', 'RTSP (554)'],
          category: DeviceCategory.cameraCandidate,
          confidence: ConfidenceLevel.high,
        ),
        _device(key: 'mac:AA:BB:CC:00:00:03', ip: '192.168.1.40'),
      ],
    );

    expect(result.usesExplicitReference, isTrue);
    expect(result.addedDevices.single.stableKey, 'mac:AA:BB:CC:00:00:03');
    expect(result.missingDevices.single.stableKey, 'mac:AA:BB:CC:00:00:02');
    expect(result.changedDevices, hasLength(1));
    final change = result.changedDevices.single;
    expect(change.ipChanged, isTrue);
    expect(change.addedServices, ['RTSP (554)']);
    expect(change.categoryChanged, isTrue);
    expect(change.confidenceChanged, isTrue);
  });

  test('güçlü kimlik kanıtının kaybolmasını düşüş olarak işaretler', () {
    final result = comparator.compare(
      baselineSessionId: 1,
      baselineCompletedAt: DateTime(2026),
      usesExplicitReference: false,
      baselineDevices: [
        _device(key: 'device-1', ip: '192.168.1.20', mac: 'B8:27:EB:12:34:56'),
      ],
      currentDevices: [_device(key: 'device-1', ip: '192.168.1.20')],
    );

    final change = result.changedDevices.single;
    expect(change.previousIdentityQuality, ObservedIdentityQuality.strong);
    expect(change.currentIdentityQuality, ObservedIdentityQuality.weak);
    expect(change.identityQualityDegraded, isTrue);
  });

  test('mDNS kimliğini ağ kapsamlı olarak değerlendirir', () {
    final device = _device(
      key: 'device-1',
      ip: '192.168.1.20',
      evidence: const [
        DeviceEvidence(
          source: DeviceEvidenceSource.mdns,
          description: 'mDNS servisi',
          identifier: 'salon-cihazi',
        ),
      ],
    );

    expect(
      comparator.identityQuality(device),
      ObservedIdentityQuality.networkScoped,
    );
  });
}

DeviceObservation _device({
  required String key,
  required String ip,
  String? mac,
  List<String> services = const [],
  List<DeviceEvidence> evidence = const [],
  DeviceCategory category = DeviceCategory.unknown,
  ConfidenceLevel confidence = ConfidenceLevel.none,
}) {
  return DeviceObservation(
    id: key,
    stableKey: key,
    ipAddress: ip,
    displayName: key,
    macAddress: mac,
    macStatus: mac == null ? MacStatus.notObserved : MacStatus.available,
    services: services,
    evidence: evidence,
    category: category,
    confidence: confidence,
  );
}
