import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

void main() {
  group('ScanPlan', () {
    test('/24 ağını hesaplar ve telefonun adresini dışarıda bırakır', () {
      final plan = ScanPlan.fromNetwork(_network('192.168.1.24', 24));

      expect(plan.networkAddress, '192.168.1.0');
      expect(plan.broadcastAddress, '192.168.1.255');
      expect(plan.targets, hasLength(253));
      expect(plan.targets, isNot(contains('192.168.1.0')));
      expect(plan.targets, isNot(contains('192.168.1.24')));
      expect(plan.targets, isNot(contains('192.168.1.255')));
      expect(plan.isTruncated, isFalse);
    });

    test('/30 ağında yalnızca diğer kullanılabilir adresi üretir', () {
      final plan = ScanPlan.fromNetwork(_network('10.0.0.1', 30));

      expect(plan.targets, ['10.0.0.2']);
      expect(plan.networkAddress, '10.0.0.0');
      expect(plan.broadcastAddress, '10.0.0.3');
    });

    test('büyük ağı 254 uzak hedefle sınırlar', () {
      final plan = ScanPlan.fromNetwork(_network('172.16.10.20', 16));

      expect(plan.targets, hasLength(254));
      expect(plan.targets, isNot(contains('172.16.10.20')));
      expect(plan.isTruncated, isTrue);
    });

    test('genel IPv4 adresini reddeder', () {
      expect(
        () => ScanPlan.fromNetwork(_network('8.8.8.8', 24)),
        throwsA(
          isA<ScanPlanningException>().having(
            (error) => error.code,
            'code',
            'PUBLIC_RANGE_BLOCKED',
          ),
        ),
      );
    });

    test('VPN ve desteklenmeyen ağ üzerinden taramayı reddeder', () {
      expect(
        () => ScanPlan.fromNetwork(_network('192.168.1.5', 24, isVpn: true)),
        throwsA(
          isA<ScanPlanningException>().having(
            (error) => error.code,
            'code',
            'VPN_ACTIVE',
          ),
        ),
      );
      expect(
        () => ScanPlan.fromNetwork(_network('192.168.1.5', 24, isWifi: false)),
        throwsA(
          isA<ScanPlanningException>().having(
            (error) => error.code,
            'code',
            'LOCAL_NETWORK_REQUIRED',
          ),
        ),
      );
    });

    test('Ethernet bağlantısını yerel ağ olarak kabul eder', () {
      final plan = ScanPlan.fromNetwork(
        _network('192.168.1.24', 24, isWifi: false, isEthernet: true),
      );

      expect(plan.targets, isNotEmpty);
      expect(plan.network.isEthernet, isTrue);
    });

    test('özel aralığın dışına taşan geniş prefix değerini reddeder', () {
      expect(
        () => ScanPlan.fromNetwork(_network('192.168.1.5', 8)),
        throwsA(
          isA<ScanPlanningException>().having(
            (error) => error.code,
            'code',
            'RANGE_LEAVES_PRIVATE_NETWORK',
          ),
        ),
      );
    });
  });
}

NetworkSnapshot _network(
  String address,
  int prefix, {
  bool isWifi = true,
  bool isEthernet = false,
  bool isVpn = false,
}) {
  return NetworkSnapshot(
    localIpv4: address,
    prefixLength: prefix,
    interfaceName: 'wlan0',
    gatewayIpv4: '192.168.1.1',
    isWifi: isWifi,
    isEthernet: isEthernet,
    isVpn: isVpn,
  );
}
