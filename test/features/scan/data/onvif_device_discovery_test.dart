import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';
import 'package:spy_dev_det/features/scan/data/onvif_device_discovery.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';
import 'package:spy_dev_det/features/scan/domain/scan_plan.dart';

void main() {
  const requestId = 'urn:uuid:11111111-2222-4333-8444-555555555555';

  test('geçerli ProbeMatch alanlarını güvenli biçimde ayrıştırır', () {
    final matches = OnvifProbeResponse.tryParse(
      utf8.encode(_response(relatesTo: requestId)),
      expectedRelatesTo: const [requestId],
    );

    expect(matches, hasLength(1));
    final match = matches!.single;
    expect(match.endpointAddress, 'urn:uuid:camera-1');
    expect(match.types, contains('dn:NetworkVideoTransmitter'));
    expect(match.deviceName, 'Salon Kamera');
    expect(match.xAddrs, ['http://192.168.1.40/onvif/device_service']);
  });

  test('yanlış istek kimliği ve DTD içeren XML reddedilir', () {
    expect(
      OnvifProbeResponse.tryParse(
        utf8.encode(_response(relatesTo: 'urn:uuid:different')),
        expectedRelatesTo: const [requestId],
      ),
      isNull,
    );
    expect(
      OnvifProbeResponse.tryParse(
        utf8.encode('<!DOCTYPE foo [<!ENTITY x "test">]><foo>&x;</foo>'),
        expectedRelatesTo: const [requestId],
      ),
      isNull,
    );
  });

  test('eski WS-Discovery namespace kullanan yanıtı da kabul eder', () {
    final legacy = _response(relatesTo: requestId)
        .replaceAll(
          'http://www.w3.org/2005/08/addressing',
          'http://schemas.xmlsoap.org/ws/2004/08/addressing',
        )
        .replaceAll(
          'http://docs.oasis-open.org/ws-dd/ns/discovery/2009/01',
          'http://schemas.xmlsoap.org/ws/2005/04/discovery',
        );

    final matches = OnvifProbeResponse.tryParse(
      utf8.encode(legacy),
      expectedRelatesTo: const [requestId],
    );

    expect(matches, hasLength(1));
    expect(matches!.single.endpointAddress, 'urn:uuid:camera-1');
  });

  test('bozuk ve aşırı büyük yanıt reddedilir', () {
    expect(
      OnvifProbeResponse.tryParse(
        utf8.encode('<Envelope><ProbeMatch>'),
        expectedRelatesTo: const [requestId],
      ),
      isNull,
    );
    expect(
      OnvifProbeResponse.tryParse(
        List<int>.filled(16385, 65),
        expectedRelatesTo: const [requestId],
      ),
      isNull,
    );
  });

  test('önceden iptal edilmiş tarama socket açmadan tamamlanır', () async {
    final token = ScanCancellationToken()..cancel();
    final plan = ScanPlan.fromNetwork(
      const NetworkSnapshot(
        localIpv4: '192.168.1.20',
        prefixLength: 30,
        interfaceName: 'test',
        gatewayIpv4: '192.168.1.21',
        isWifi: true,
        isVpn: false,
      ),
    );

    final result = await const OnvifDeviceDiscovery().discover(plan, token);

    expect(result.devices, isEmpty);
    expect(result.metrics.sentRequests, 0);
  });
}

String _response({required String relatesTo}) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" '
    'xmlns:a="http://www.w3.org/2005/08/addressing" '
    'xmlns:d="http://docs.oasis-open.org/ws-dd/ns/discovery/2009/01" '
    'xmlns:dn="http://www.onvif.org/ver10/network/wsdl">'
    '<s:Header><a:RelatesTo>$relatesTo</a:RelatesTo></s:Header>'
    '<s:Body><d:ProbeMatches><d:ProbeMatch>'
    '<a:EndpointReference><a:Address>urn:uuid:camera-1</a:Address>'
    '</a:EndpointReference>'
    '<d:Types>dn:NetworkVideoTransmitter</d:Types>'
    '<d:Scopes>onvif://www.onvif.org/name/Salon%20Kamera</d:Scopes>'
    '<d:XAddrs>http://192.168.1.40/onvif/device_service ftp://bad.example/file</d:XAddrs>'
    '<d:MetadataVersion>1</d:MetadataVersion>'
    '</d:ProbeMatch></d:ProbeMatches></s:Body></s:Envelope>';
