import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/data/app_database.dart';
import 'package:spy_dev_det/features/history/data/drift_scan_history_repository.dart';
import 'package:spy_dev_det/features/history/domain/scan_history_repository.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/scan_mode.dart';
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

  test(
    'referans tarama sonraki karşılaştırmalarda kalıcı olarak kullanılır',
    () async {
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
      final firstSession = (await repository.getHistory()).single;
      await repository.setReferenceScan(firstSession.id);

      await repository.recordCompletedScan(
        _record(ipAddress: '192.168.1.20', minute: 5),
      );
      await repository.recordCompletedScan(
        _record(ipAddress: '192.168.1.20', minute: 10),
      );

      final history = await repository.getHistory();
      expect(history.first.missingDevices, hasLength(1));
      expect(history.last.isReference, isTrue);
      expect(history.last.isPresenceComparable, isTrue);
    },
  );

  test('hızlı tarama ağ referansı yapılamaz', () async {
    await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0, scanMode: ScanMode.quick),
    );
    final session = (await repository.getHistory()).single;

    expect(
      () => repository.setReferenceScan(session.id),
      throwsA(isA<StateError>()),
    );
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

  test(
    'sonradan bulunan güçlü kimliği mevcut cihaz profiline bağlar',
    () async {
      final firstRecord = _record(ipAddress: '192.168.1.20', minute: 0);
      final first = await repository.recordCompletedScan(
        CompletedScanRecord(
          networkKey: firstRecord.networkKey,
          report: firstRecord.report,
          elapsed: firstRecord.elapsed,
          devices: const [
            DeviceObservation(
              id: 'ip-only',
              ipAddress: '192.168.1.20',
              displayName: 'İlk gözlem',
              macStatus: MacStatus.notObserved,
              services: [],
            ),
          ],
        ),
      );
      await repository.updateDeviceProfile(
        stableKey: first.single.stableKey!,
        isKnown: true,
        customName: 'Salon cihazı',
        note: null,
      );

      final withMac = await repository.recordCompletedScan(
        _record(ipAddress: '192.168.1.20', minute: 5),
      );
      final afterDhcpChange = await repository.recordCompletedScan(
        _record(ipAddress: '192.168.1.45', minute: 10),
      );

      expect(withMac.single.stableKey, first.single.stableKey);
      expect(afterDhcpChange.single.stableKey, first.single.stableKey);
      expect(afterDhcpChange.single.familiarity, DeviceFamiliarity.known);
      expect(afterDhcpChange.single.effectiveDisplayName, 'Salon cihazı');
    },
  );

  test('aynı IP adresine gelen farklı MAC cihaz profilini devralmaz', () async {
    final first = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0),
    );
    await repository.updateDeviceProfile(
      stableKey: first.single.stableKey!,
      isKnown: true,
      customName: 'Eski cihaz',
      note: null,
    );

    final replacement = await repository.recordCompletedScan(
      _record(
        ipAddress: '192.168.1.20',
        minute: 5,
        devices: const [
          (ipAddress: '192.168.1.20', macAddress: '00:17:88:12:34:56'),
        ],
      ),
    );

    expect(replacement.single.stableKey, isNot(first.single.stableKey));
    expect(replacement.single.familiarity, DeviceFamiliarity.newDevice);
    expect(replacement.single.customName, isNull);
  });

  test('eski IP tabanlı kimlik yeni cihaza süresiz aktarılmaz', () async {
    CompletedScanRecord ipOnlyRecord(int minute) {
      final base = _record(ipAddress: '192.168.1.20', minute: minute);
      return CompletedScanRecord(
        networkKey: base.networkKey,
        report: base.report,
        elapsed: base.elapsed,
        devices: const [
          DeviceObservation(
            id: 'ip-only',
            ipAddress: '192.168.1.20',
            displayName: 'Kimliği zayıf cihaz',
            macStatus: MacStatus.notObserved,
            services: [],
          ),
        ],
      );
    }

    final first = await repository.recordCompletedScan(ipOnlyRecord(0));
    await repository.updateDeviceProfile(
      stableKey: first.single.stableKey!,
      isKnown: true,
      customName: 'Önceki cihaz',
      note: null,
    );

    final replacement = await repository.recordCompletedScan(
      ipOnlyRecord(8 * 24 * 60),
    );

    expect(replacement.single.stableKey, isNot(first.single.stableKey));
    expect(replacement.single.familiarity, DeviceFamiliarity.newDevice);
    expect(replacement.single.customName, isNull);
  });

  test('gateway MAC geçici olarak kaybolsa da aynı ağı kullanır', () async {
    const baseKey = '192.168.1.0/24|gateway:192.168.1.1';
    const strongKey = '$baseKey|gateway-mac:B8:27:EB:12:34:56';
    await repository.recordCompletedScan(
      _record(
        ipAddress: '192.168.1.20',
        minute: 0,
        networkIdentityKeys: const [strongKey, baseKey],
      ),
    );
    await repository.recordCompletedScan(
      _record(
        ipAddress: '192.168.1.20',
        minute: 5,
        networkIdentityKeys: const [baseKey],
      ),
    );

    final history = await repository.getHistory();
    expect(history, hasLength(2));
    expect(history.first.networkKey, strongKey);
    expect(history.last.networkKey, strongKey);
  });

  test('eski sürümdeki güçlü ağ anahtarını geçişte yeniden kullanır', () async {
    const baseKey = '192.168.1.0/24|gateway:192.168.1.1';
    const strongKey = '$baseKey|gateway-mac:B8:27:EB:12:34:56';
    await repository.recordCompletedScan(
      _record(
        ipAddress: '192.168.1.20',
        minute: 0,
        networkIdentityKeys: const [strongKey],
      ),
    );
    await database.delete(database.networkIdentityAliases).go();
    await database.delete(database.networkProfiles).go();

    await repository.recordCompletedScan(
      _record(
        ipAddress: '192.168.1.20',
        minute: 5,
        networkIdentityKeys: const [baseKey],
      ),
    );

    final history = await repository.getHistory();
    expect(history, hasLength(2));
    expect(history.first.networkKey, strongKey);
    expect(history.last.networkKey, strongKey);
  });

  test(
    'aynı alt ağdaki farklı gateway MAC için yeni ağ profili açar',
    () async {
      const baseKey = '192.168.1.0/24|gateway:192.168.1.1';
      const firstStrongKey = '$baseKey|gateway-mac:B8:27:EB:12:34:56';
      const secondStrongKey = '$baseKey|gateway-mac:00:17:88:12:34:56';
      await repository.recordCompletedScan(
        _record(
          ipAddress: '192.168.1.20',
          minute: 0,
          networkIdentityKeys: const [firstStrongKey, baseKey],
        ),
      );
      await repository.recordCompletedScan(
        _record(
          ipAddress: '192.168.1.20',
          minute: 5,
          networkIdentityKeys: const [secondStrongKey, baseKey],
        ),
      );

      final history = await repository.getHistory();
      expect(history.first.networkKey, secondStrongKey);
      expect(history.last.networkKey, firstStrongKey);
    },
  );

  test(
    'aynı adresleri kullanan farklı gateway servis kimliklerini ayırır',
    () async {
      const baseKey = '192.168.1.0/24|gateway:192.168.1.1';
      const firstStrongKey = '$baseKey|gateway-service:ssdp%3Auuid%3Arouter-1';
      const secondStrongKey = '$baseKey|gateway-service:ssdp%3Auuid%3Arouter-2';
      await repository.recordCompletedScan(
        _record(
          ipAddress: '192.168.1.20',
          minute: 0,
          networkIdentityKeys: const [firstStrongKey, baseKey],
        ),
      );
      await repository.recordCompletedScan(
        _record(
          ipAddress: '192.168.1.20',
          minute: 5,
          networkIdentityKeys: const [secondStrongKey, baseKey],
        ),
      );

      final history = await repository.getHistory();
      expect(history.first.networkKey, secondStrongKey);
      expect(history.last.networkKey, firstStrongKey);
    },
  );

  test('sahiplik ve kategori düzeltmesini sonraki taramada korur', () async {
    final first = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0),
    );
    await repository.updateDeviceProfile(
      stableKey: first.single.stableKey!,
      isKnown: false,
      isOwned: true,
      categoryOverride: DeviceCategory.mediaDevice,
      customName: 'Salon cihazı',
      note: null,
    );

    final next = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.21', minute: 5),
    );

    expect(next.single.isOwned, isTrue);
    expect(next.single.familiarity, DeviceFamiliarity.known);
    expect(next.single.categoryOverride, DeviceCategory.mediaDevice);
    expect(next.single.effectiveCategory, DeviceCategory.mediaDevice);
  });

  test('cihaz profillerini listeler ve seçilen profili unutur', () async {
    final saved = await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0),
    );
    await repository.updateDeviceProfile(
      stableKey: saved.single.stableKey!,
      isKnown: true,
      customName: 'Kayıtlı cihaz',
      note: 'Yerel not',
    );

    final profiles = await repository.getKnownDevices();
    expect(profiles.single.effectiveDisplayName, 'Kayıtlı cihaz');
    expect(profiles.single.isKnown, isTrue);

    await repository.forgetDevice(profiles.single.stableKey);
    expect(await repository.getKnownDevices(), isEmpty);
    expect(await repository.getHistory(), hasLength(1));
  });

  test('ağ profillerini adlandırır ve geçmişi ağa göre filtreler', () async {
    const firstNetwork = '192.168.1.0/24|gateway:192.168.1.1';
    const secondNetwork = '10.0.0.0/24|gateway:10.0.0.1';
    await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0, networkKey: firstNetwork),
    );
    await repository.recordCompletedScan(
      _record(ipAddress: '10.0.0.20', minute: 5, networkKey: secondNetwork),
    );

    await repository.renameNetworkProfile(
      networkKey: firstNetwork,
      customName: 'Ev ağı',
    );
    final profiles = await repository.getNetworkProfiles();
    final firstProfile = profiles.singleWhere(
      (profile) => profile.networkKey == firstNetwork,
    );
    final filteredHistory = await repository.getHistory(
      networkKey: firstNetwork,
    );

    expect(profiles, hasLength(2));
    expect(firstProfile.displayName, 'Ev ağı');
    expect(firstProfile.scanCount, 1);
    expect(filteredHistory, hasLength(1));
    expect(filteredHistory.single.networkKey, firstNetwork);
  });

  test(
    'tek ağın profilini ve geçmişini diğer ağlara dokunmadan siler',
    () async {
      const firstNetwork = '192.168.1.0/24|gateway:192.168.1.1';
      const secondNetwork = '10.0.0.0/24|gateway:10.0.0.1';
      await repository.recordCompletedScan(
        _record(ipAddress: '192.168.1.20', minute: 0, networkKey: firstNetwork),
      );
      await repository.recordCompletedScan(
        _record(ipAddress: '10.0.0.20', minute: 5, networkKey: secondNetwork),
      );

      await repository.deleteNetworkData(firstNetwork);

      final profiles = await repository.getNetworkProfiles();
      expect(profiles.map((profile) => profile.networkKey), [secondNetwork]);
      expect(await repository.getHistory(networkKey: firstNetwork), isEmpty);
      expect(
        await repository.getHistory(networkKey: secondNetwork),
        hasLength(1),
      );
    },
  );

  test('tarama modunu geçmişte saklar', () async {
    await repository.recordCompletedScan(
      _record(ipAddress: '192.168.1.20', minute: 0, scanMode: ScanMode.quick),
    );

    final history = await repository.getHistory();

    expect(history.single.scanMode, ScanMode.quick);
  });

  test('saklama sınırı değişince eski taramaları hemen temizler', () async {
    for (var index = 0; index < 28; index++) {
      await repository.recordCompletedScan(
        _record(ipAddress: '192.168.1.20', minute: index),
      );
    }
    repository = DriftScanHistoryRepository(
      database,
      maxSessionsPerNetwork: 25,
    );
    await repository.applyRetentionLimit();

    final history = await repository.getHistory(limit: 200);

    expect(history, hasLength(25));
    expect(history.first.startedAt, DateTime(2026, 10, 15, 10, 27));
    expect(history.last.startedAt, DateTime(2026, 10, 15, 10, 3));
  });
}

CompletedScanRecord _record({
  required String ipAddress,
  required int minute,
  List<({String ipAddress, String macAddress})>? devices,
  bool discoveryComplete = true,
  List<String> networkIdentityKeys = const [],
  String networkKey = '192.168.1.0/24|gateway:192.168.1.1',
  ScanMode scanMode = ScanMode.detailed,
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
    networkKey: networkKey,
    networkIdentityKeys: networkIdentityKeys,
    report: ScanReport(
      startedAt: startedAt,
      completedAt: completedAt,
      methods: methods,
      scanMode: scanMode,
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
