import 'package:flutter_test/flutter_test.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:spy_dev_det/features/scan/data/mdns_device_discovery.dart';

void main() {
  test('mDNS TXT verisinden yalnız güvenli cihaz alanlarını kabul eder', () {
    final metadata = MdnsTxtMetadata.fromRecords(const [
      TxtResourceRecord(
        'Salon._airplay._tcp.local',
        0,
        text:
            'model=TV-2026\nmanufacturer=Örnek\npassword=gizli\nfn=Salon TV\n',
      ),
    ]);

    expect(metadata.values['model'], 'TV-2026');
    expect(metadata.values['manufacturer'], 'Örnek');
    expect(metadata.values['fn'], 'Salon TV');
    expect(metadata.values, isNot(contains('password')));
    expect(metadata.summary, contains('model=TV-2026'));
  });

  test('mDNS TXT değerlerini temizler ve uzunluğu sınırlar', () {
    final metadata = MdnsTxtMetadata.fromRecords([
      TxtResourceRecord(
        'Cihaz._http._tcp.local',
        0,
        text: 'md=${'A' * 100}\u0000\u202E\n',
      ),
    ]);

    expect(metadata.values['md'], hasLength(80));
    expect(metadata.values['md'], isNot(contains('\u0000')));
    expect(metadata.values['md'], isNot(contains('\u202E')));
  });
}
