import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/data/app_database.dart';
import 'package:spy_dev_det/features/history/data/drift_scan_history_repository.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  late AppDatabase database;
  late DriftScanHistoryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftScanHistoryRepository(database);
  });

  tearDown(() => database.close());

  test('yeni cihazı kaydeder ve sonraki taramada yeniden tanır', () async {
    final first = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0),
    );
    final second = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.45', minute: 5),
    );

    expect(first.single.familiarity, DeviceFamiliarity.newDevice);
    expect(second.single.familiarity, DeviceFamiliarity.seenBefore);
    expect(first.single.stableKey, second.single.stableKey);

    final history = await repository.getHistory();
    expect(history, hasLength(2));
    expect(history.first.newDeviceCount, 0);
    expect(history.last.newDeviceCount, 1);
  });

  test('bilinen cihaz adı ve notu sonraki taramada korunur', () async {
    final first = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0),
    );
    await repository.updateDeviceProfile(
      stableKey: first.single.stableKey!,
      isKnown: true,
      customName: 'Salon cihazı',
      note: 'Bana ait',
    );

    final next = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.21', minute: 10),
    );

    expect(next.single.familiarity, DeviceFamiliarity.known);
    expect(next.single.effectiveDisplayName, 'Salon cihazı');
    expect(next.single.note, 'Bana ait');

    final history = await repository.getHistory();
    final details = await repository.getDetails(history.first.id);
    expect(details?.devices.single.effectiveDisplayName, 'Salon cihazı');
  });

  test('tam taramada artık görülmeyen cihazları listeler', () async {
    await repository.recordCompletedScan(
      _record(
        ipAddress: '192.168.1.20',
        minute: 0,
        devices: const [
          (ipAddress: '192.168.1.20', macAddress: 'B8:27:EB:12:34:56'),
          (ipAddress: '192.168.1.30', macAddress: '00:17:88:12:34:56'),
        ],
      ),
    );
    await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 5),
    );

    final history = await repository.getHistory();

    expect(history.first.missingDevices, hasLength(1));
    expect(history.first.missingDevices.single.lastIpAddress, '192.168.1.30');
  });

  test('geçmiş silinse de bilinen cihaz profili korunur', () async {
    final first = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0),
    );
    await repository.updateDeviceProfile(
      stableKey: first.single.stableKey!,
      isKnown: true,
      customName: 'Kişisel cihaz',
      note: null,
    );
    await repository.clearHistory();

    expect(await repository.getHistory(), isEmpty);

    final next = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.21', minute: 5),
    );
    expect(next.single.familiarity, DeviceFamiliarity.known);
    expect(next.single.effectiveDisplayName, 'Kişisel cihaz');
  });

  test('tüm yerel veriler silinince cihaz profili de unutulur', () async {
    final first = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0),
    );
    await repository.updateDeviceProfile(
      stableKey: first.single.stableKey!,
      isKnown: true,
      customName: 'Silinecek cihaz',
      note: 'Yerel not',
    );

    await repository.clearAllData();

    expect(await repository.getHistory(), isEmpty);
    final next = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.21', minute: 5),
    );
    expect(next.single.familiarity, DeviceFamiliarity.newDevice);
    expect(next.single.customName, isNull);
    expect(next.single.note, isNull);
  });

  test('taramayı çalıştıran cihaz ilk kayıtta bilinen sayılır', () async {
    final base = _record(ipAddress: '192.168.1.10', minute: 0);
    final saved = await repository.recordCompletedScan(
      CompletedScanRecord(
        networkKey: base.networkKey,
        report: base.report,
        elapsed: base.elapsed,
        devices: const [
          DeviceObservation(
            id: 'local-device',
            ipAddress: '192.168.1.10',
            displayName: 'Bu cihaz',
            macStatus: MacStatus.notObserved,
            services: [],
            discoveryMethod: 'Yerel ağ bilgisi',
            evidence: [
              DeviceEvidence(
                source: DeviceEvidenceSource.network,
                description: 'Taramanın çalıştığı cihaz',
              ),
            ],
          ),
        ],
      ),
    );

    expect(saved.single.stableKey, 'local:this-installation');
    expect(saved.single.familiarity, DeviceFamiliarity.known);
    expect((await repository.getHistory()).single.newDeviceCount, 0);
  });

  test('kısmi taramada cihazı görülmedi olarak işaretlemez', () async {
    await repository.recordCompletedScan(
      _record(
        ipAddress: '192.168.1.20',
        minute: 0,
        devices: const [
          (ipAddress: '192.168.1.20', macAddress: 'B8:27:EB:12:34:56'),
          (ipAddress: '192.168.1.30', macAddress: '00:17:88:12:34:56'),
        ],
      ),
    );
    await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 5, discoveryComplete: false),
    );

    final history = await repository.getHistory();
    expect(history.first.missingDevices, isEmpty);
  });

  test('keşif tanılama sayaçlarını geçmişte korur', () async {
    final base = _record(ipAddress: '192.168.1.20', minute: 0);
    final report = base.report.withMethod(
      const DiscoveryMethodResult(
        method: DiscoveryMethod.onvif,
        phase: DiscoveryMethodPhase.completed,
        deviceCount: 1,
        elapsed: Duration(milliseconds: 2400),
        metrics: DiscoveryMetrics(
          sentRequests: 2,
          receivedResponses: 3,
          acceptedResponses: 1,
          ignoredResponses: 2,
          multicastLockAcquired: true,
          detail: 'WS-Discovery Probe/ProbeMatch',
        ),
      ),
    );

    await repository.recordCompletedScan(
      CompletedScanRecord(
        networkKey: base.networkKey,
        report: report,
        elapsed: base.elapsed,
        devices: base.devices,
      ),
    );

    final saved =
        (await repository.getHistory()).single.methods[DiscoveryMethod.onvif]!;
    expect(saved.metrics.sentRequests, 2);
    expect(saved.metrics.receivedResponses, 3);
    expect(saved.metrics.multicastLockAcquired, isTrue);
    expect(saved.metrics.detail, 'WS-Discovery Probe/ProbeMatch');
  });
}

CompletedScanRecord _record({
  required String ipAddress,
  required int minute,
  List<({String ipAddress, String macAddress})>? devices,
  bool discoveryComplete = true,
}) {
  final startedAt = DateTime(2026, 10, 15, 10, minute);
  final completedAt = startedAt.add(const Duration(seconds: 2));
  final methods = {
    for (final method in DiscoveryMethod.values)
      method: DiscoveryMethodResult(
        method: method,
        phase: !discoveryComplete && method == DiscoveryMethod.ssdp
            ? DiscoveryMethodPhase.unavailable
            : DiscoveryMethodPhase.completed,
        deviceCount: 1,
        elapsed: const Duration(milliseconds: 500),
      ),
  };
  return CompletedScanRecord(
    networkKey: '192.168.1.0/24|gateway:192.168.1.1',
    report: ScanReport(
      startedAt: startedAt,
      completedAt: completedAt,
      methods: methods,
    ),
    elapsed: const Duration(seconds: 2),
    devices:
        (devices ?? [(ipAddress: ipAddress, macAddress: 'B8:27:EB:12:34:56')])
            .map(
              (value) => DeviceObservation(
                id: 'device-${value.ipAddress}',
                ipAddress: value.ipAddress,
                displayName: 'Cihaz ${value.ipAddress}',
                macAddress: value.macAddress,
                macStatus: MacStatus.available,
                services: const ['HTTP (80)'],
                discoveryMethod: 'TCP bağlantı denemesi',
              ),
            )
            .toList(),
  );
}
