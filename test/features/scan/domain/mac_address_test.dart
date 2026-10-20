import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/mac_address.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_enricher.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MacAddress', () {
    test('geçerli adresi standart biçime getirip üreticiyi bulur', () {
      final address = MacAddress.tryParse('b8-27-eb-12-34-56');

      expect(address?.value, 'B8:27:EB:12:34:56');
      expect(address?.isLocallyAdministered, isFalse);
      expect(
        const MacVendorRepository().lookup(address!),
        'Raspberry Pi Foundation',
      );
    });

    test('yerel yönetilen MAC için üretici tahmin edilmez', () {
      final address = MacAddress.tryParse('02:11:22:33:44:55');

      expect(address?.isLocallyAdministered, isTrue);
      expect(const MacVendorRepository().lookup(address!), isNull);
    });

    test('yayın ve multicast adresleri reddedilir', () {
      expect(MacAddress.tryParse('FF:FF:FF:FF:FF:FF'), isNull);
      expect(MacAddress.tryParse('01:00:5E:00:00:01'), isNull);
    });
  });

  test('çevrimdışı IEEE asset en uzun prefix eşleşmesini kullanır', () async {
    const repository = AssetMacVendorRepository();
    final status = await repository.load();

    expect(status.loaded, isTrue);
    expect(status.entryCount, greaterThan(50000));
    expect(
      repository.lookup(MacAddress.tryParse('00:55:DA:01:23:45')!),
      'Shinko Technos co.,ltd.',
    );
    expect(
      repository.lookup(MacAddress.tryParse('00:1B:C5:00:01:23')!),
      'Converging Systems Inc.',
    );
    expect(
      repository.lookup(MacAddress.tryParse('02:11:22:33:44:55')!),
      isNull,
    );
  });

  test('komşu tablosu cihazı MAC ve üreticiyle zenginleştirir', () {
    const device = DeviceObservation(
      id: 'device-1',
      ipAddress: '192.168.1.20',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: [],
    );
    const snapshot = NeighborSnapshot(
      available: true,
      entries: [
        NeighborEntry(
          ipAddress: '192.168.1.20',
          macAddress: 'B8:27:EB:12:34:56',
        ),
      ],
    );

    final result = const NeighborEnricher().enrich(device, snapshot);

    expect(result.macStatus, MacStatus.available);
    expect(result.macAddress, 'B8:27:EB:12:34:56');
    expect(result.vendor, 'Raspberry Pi Foundation');
    expect(result.evidence, isNotEmpty);
  });

  test('Android komşu tablosu kısıtını genel hatadan ayırır', () {
    const device = DeviceObservation(
      id: 'android-device',
      ipAddress: '192.168.1.30',
      displayName: 'Ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: [],
    );
    const snapshot = NeighborSnapshot.unavailable(
      unavailableReason: NeighborSnapshotUnavailableReason.androidRestricted,
    );

    final result = const NeighborEnricher().enrich(device, snapshot);

    expect(result.macStatus, MacStatus.platformRestricted);
    expect(result.macStatus.label, contains('Android 10'));
  });

  test(
    'tablo kullanılamasa da sağlanan yerel bağdaştırıcı MAC adresini kullanır',
    () {
      const snapshot = NeighborSnapshot(
        available: false,
        entries: [
          NeighborEntry(
            ipAddress: '192.168.1.20',
            macAddress: 'B8:27:EB:12:34:56',
          ),
        ],
        unavailableReason:
            NeighborSnapshotUnavailableReason.operatingSystemUnavailable,
      );
      const device = DeviceObservation(
        id: 'self',
        ipAddress: '192.168.1.20',
        displayName: 'Bu cihaz',
        macStatus: MacStatus.notObserved,
        services: [],
      );

      final result = const NeighborEnricher().enrich(device, snapshot);

      expect(result.macStatus, MacStatus.available);
      expect(result.macAddress, 'B8:27:EB:12:34:56');
    },
  );
}
