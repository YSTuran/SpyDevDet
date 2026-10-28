import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/data/ssdp_device_discovery.dart';

void main() {
  test('geçerli SSDP yanıtında yalnız izin verilen başlıkları ayrıştırır', () {
    final response = SsdpResponse.tryParse(
      latin1.encode(
        'HTTP/1.1 200 OK\r\n'
        'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
        'SERVER: Test Device/1.0\r\n'
        'USN: uuid:test::urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
        'LOCATION: http://192.168.1.20/device.xml\r\n'
        'X-Ignored: secret\r\n\r\n',
      ),
    );

    expect(response, isNotNull);
    expect(response?.server, 'Test Device/1.0');
    expect(response?.searchTarget, contains('MediaRenderer'));
    expect(response?.location, 'http://192.168.1.20/device.xml');
  });

  test('SSDP olmayan veya başlıksız paket reddedilir', () {
    expect(
      SsdpResponse.tryParse(ascii.encode('NOTIFY * HTTP/1.1\r\n')),
      isNull,
    );
    expect(SsdpResponse.tryParse(ascii.encode('HTTP/1.1 200 OK\r\n')), isNull);
  });

  test('SSDP başlığındaki C1 kontrol karakterlerini kaldırır', () {
    final response = SsdpResponse.tryParse(
      latin1.encode('HTTP/1.1 200 OK\r\nSERVER: Güvenli\u0085sahte\r\n\r\n'),
    );

    expect(response?.server, 'Güvenlisahte');
  });
}
