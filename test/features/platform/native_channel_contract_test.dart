import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/data/native_network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/network_info_repository.dart';
import 'package:spy_dev_det/features/scan/data/native_neighbor_repository.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('yusufs.turan.spydevdet/network_info');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('ağ kanalındaki geçerli platform yanıtını modele dönüştürür', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getNetworkSnapshot');
          return <String, Object?>{
            'localIpv4': '192.168.1.24',
            'prefixLength': 24,
            'interfaceName': 'wlan0',
            'isWifi': true,
            'isEthernet': false,
            'isVpn': false,
            'gatewayIpv4': '192.168.1.1',
          };
        });

    final snapshot = await const NativeNetworkInfoRepository()
        .getCurrentNetwork();

    expect(snapshot.cidr, '192.168.1.24/24');
    expect(snapshot.interfaceName, 'wlan0');
    expect(snapshot.gatewayIpv4, '192.168.1.1');
  });

  test(
    'eksik zorunlu kanal alanını güvenli uygulama hatasına çevirir',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return <String, Object?>{
              'localIpv4': '192.168.1.24',
              'prefixLength': 24,
              'interfaceName': 'wlan0',
              'isWifi': true,
              'isEthernet': false,
            };
          });

      await expectLater(
        const NativeNetworkInfoRepository().getCurrentNetwork(),
        throwsA(
          isA<NetworkInfoException>().having(
            (error) => error.code,
            'code',
            'INVALID_RESPONSE',
          ),
        ),
      );
    },
  );

  test('Android komşu tablosu kısıtını ayrı durum olarak korur', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getNeighborSnapshot');
          return <String, Object?>{
            'available': false,
            'entries': <Object>[],
            'unavailableReason': 'androidRestricted',
          };
        });

    final snapshot = await const NativeNeighborRepository().getSnapshot();

    expect(snapshot.available, isFalse);
    expect(
      snapshot.unavailableReason,
      NeighborSnapshotUnavailableReason.androidRestricted,
    );
  });

  test('komşu kanalındaki bozuk satırları yok sayar', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <String, Object?>{
            'available': true,
            'entries': <Object?>[
              <String, Object?>{
                'ipAddress': '192.168.1.20',
                'macAddress': 'B8:27:EB:12:34:56',
              },
              <String, Object?>{'ipAddress': 20, 'macAddress': null},
              'bozuk',
            ],
          };
        });

    final snapshot = await const NativeNeighborRepository().getSnapshot();

    expect(snapshot.available, isTrue);
    expect(snapshot.entries, hasLength(1));
    expect(snapshot.entries.single.ipAddress, '192.168.1.20');
  });
}
