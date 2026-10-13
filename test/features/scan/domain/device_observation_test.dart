import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/device_observation.dart';

void main() {
  group('DeviceObservation', () {
    test('üretici yoksa bilinmeyen kabul edilir', () {
      const observation = DeviceObservation(
        id: 'device-1',
        ipAddress: '192.168.1.5',
        displayName: 'Test cihazı',
        macStatus: MacStatus.notObserved,
        services: [],
      );

      expect(observation.hasKnownVendor, isFalse);
      expect(
        observation.macStatus.label,
        'MAC adresi bu taramada gözlemlenmedi',
      );
    });

    test('geçerli üretici değeri bilinen kabul edilir', () {
      const observation = DeviceObservation(
        id: 'device-2',
        ipAddress: '192.168.1.10',
        displayName: 'Test cihazı',
        macAddress: '02:00:00:00:00:02',
        macStatus: MacStatus.available,
        vendor: 'Test üreticisi',
        services: ['HTTP'],
      );

      expect(observation.hasKnownVendor, isTrue);
    });
  });
}
