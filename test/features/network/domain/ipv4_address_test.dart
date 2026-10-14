import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/domain/ipv4_address.dart';

void main() {
  group('Ipv4Address', () {
    test('adres değerini sayıya çevirip geri oluşturur', () {
      final value = Ipv4Address.parse('192.168.1.24');

      expect(Ipv4Address.format(value), '192.168.1.24');
    });

    test('geçersiz adresi reddeder', () {
      expect(
        () => Ipv4Address.parse('192.168.1.999'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Ipv4Address.parse('192.168.1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('yalnızca RFC1918 özel aralıklarını kabul eder', () {
      expect(Ipv4Address.isPrivate(Ipv4Address.parse('10.2.3.4')), isTrue);
      expect(Ipv4Address.isPrivate(Ipv4Address.parse('172.31.1.1')), isTrue);
      expect(Ipv4Address.isPrivate(Ipv4Address.parse('192.168.2.1')), isTrue);
      expect(Ipv4Address.isPrivate(Ipv4Address.parse('8.8.8.8')), isFalse);
      expect(Ipv4Address.isPrivate(Ipv4Address.parse('169.254.1.1')), isFalse);
    });
  });
}
