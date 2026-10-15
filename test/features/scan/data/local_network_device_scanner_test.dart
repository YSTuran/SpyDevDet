import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/data/local_network_device_scanner.dart';
import 'package:spy_dev_det/features/scan/data/native_multicast_lock.dart';
import 'package:spy_dev_det/features/scan/domain/device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';
import 'package:spy_dev_det/features/scan/domain/device_scanner.dart';
import 'package:spy_dev_det/features/scan/domain/neighbor_snapshot.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_event.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  test(
    'TCP, mDNS ve komşu verisini tek açıklanabilir cihazda birleştirir',
    () async {
      final plan = ScanPlan.fromNetwork(
        const NetworkSnapshot(
          localIpv4: '192.168.1.2',
          prefixLength: 29,
          interfaceName: 'test',
          gatewayIpv4: '192.168.1.1',
          isWifi: true,
          isVpn: false,
        ),
      );
      final scanner = LocalNetworkDeviceScanner(
        tcpScanner: const _TcpScanner(),
        reachabilityDiscovery: const _ReachabilityDiscovery(),
        mdnsDiscovery: const _MdnsDiscovery(),
        ssdpDiscovery: const _EmptyDiscovery(),
        neighborRepository: const _NeighborRepository(),
        multicastLock: const _MulticastLock(),
      );

      final events = await scanner.scan(plan, ScanCancellationToken()).toList();
      final observations = events.whereType<DeviceObserved>().toList();
      final device = observations
          .lastWhere((event) => event.device.ipAddress == '192.168.1.3')
          .device;
      final methodResults = <DiscoveryMethod, DiscoveryMethodResult>{
        for (final event in events.whereType<ScanMethodStatusChanged>())
          event.result.method: event.result,
      };

      expect(events.whereType<ScanCompleted>(), hasLength(1));
      expect(events.whereType<ScanCancelled>(), isEmpty);
      expect(
        observations.any(
          (event) =>
              event.device.ipAddress == '192.168.1.2' &&
              event.device.displayName == 'Bu cihaz',
        ),
        isTrue,
      );
      expect(
        observations.any((event) => event.device.ipAddress == '192.168.1.4'),
        isTrue,
      );
      expect(
        methodResults.values.map((result) => result.phase),
        everyElement(DiscoveryMethodPhase.completed),
      );
      expect(methodResults.keys, containsAll(DiscoveryMethod.values));
      expect(device.ipAddress, '192.168.1.3');
      expect(device.displayName, 'Ofis yazıcısı');
      expect(device.discoveryMethod, contains('TCP'));
      expect(device.discoveryMethod, contains('mDNS'));
      expect(device.category, DeviceCategory.printer);
      expect(device.confidence, ConfidenceLevel.high);
      expect(device.macAddress, 'B8:27:EB:12:34:56');
      expect(device.vendor, 'Raspberry Pi Foundation');
    },
  );
}

class _ReachabilityDiscovery implements DeviceDiscovery {
  const _ReachabilityDiscovery();

  @override
  Future<List<DeviceObservation>> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async => const [
    DeviceObservation(
      id: 'device-192.168.1.4',
      ipAddress: '192.168.1.4',
      displayName: 'Erişilebilir ağ cihazı',
      macStatus: MacStatus.notObserved,
      services: [],
      discoveryMethod: 'Ağ erişilebilirlik kontrolü',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.reachability,
          description: 'Cihaz erişilebilirlik kontrolüne yanıt verdi',
        ),
      ],
    ),
  ];
}

class _TcpScanner implements DeviceScanner {
  const _TcpScanner();

  @override
  Stream<ScanEvent> scan(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async* {
    yield ScanStarted(totalTargets: plan.targets.length);
    yield const DeviceObserved(
      DeviceObservation(
        id: 'device-192.168.1.3',
        ipAddress: '192.168.1.3',
        displayName: 'Ağ cihazı',
        macStatus: MacStatus.notObserved,
        services: ['HTTP (80)'],
        discoveryMethod: 'TCP bağlantı denemesi',
        evidence: [
          DeviceEvidence(
            source: DeviceEvidenceSource.tcp,
            description: 'TCP 80 portu bağlantı kabul etti',
            port: 80,
          ),
        ],
      ),
    );
    yield ScanProgress(
      completedTargets: plan.targets.length,
      totalTargets: plan.targets.length,
    );
    yield ScanCompleted(
      completedTargets: plan.targets.length,
      elapsed: Duration.zero,
    );
  }
}

class _MdnsDiscovery implements DeviceDiscovery {
  const _MdnsDiscovery();

  @override
  Future<List<DeviceObservation>> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async => const [
    DeviceObservation(
      id: 'device-192.168.1.3',
      ipAddress: '192.168.1.3',
      displayName: 'Ofis yazıcısı',
      macStatus: MacStatus.notObserved,
      services: ['_ipp._tcp.local (631)'],
      discoveryMethod: 'mDNS',
      evidence: [
        DeviceEvidence(
          source: DeviceEvidenceSource.mdns,
          description: 'mDNS servis duyurusu: _ipp._tcp.local (631)',
          serviceType: '_ipp._tcp.local',
          port: 631,
        ),
      ],
    ),
  ];
}

class _EmptyDiscovery implements DeviceDiscovery {
  const _EmptyDiscovery();

  @override
  Future<List<DeviceObservation>> discover(
    ScanPlan plan,
    ScanCancellationToken cancellationToken,
  ) async => const [];
}

class _NeighborRepository implements NeighborRepository {
  const _NeighborRepository();

  @override
  Future<NeighborSnapshot> getSnapshot() async => const NeighborSnapshot(
    available: true,
    entries: [
      NeighborEntry(ipAddress: '192.168.1.3', macAddress: 'B8:27:EB:12:34:56'),
    ],
  );
}

class _MulticastLock extends NativeMulticastLock {
  const _MulticastLock();

  @override
  Future<void> acquire() async {}

  @override
  Future<void> release() async {}
}
