import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/data/ws_netbios_device_discovery.dart';

void main() {
  const transactionId = 0x1234;

  test('NetBIOS wildcard sorgusunu sınırlı ve geçerli biçimde üretir', () {
    final query = NetbiosNodeStatusResponse.buildQuery(transactionId);

    expect(query, hasLength(50));
    expect(query.sublist(0, 4), [0x12, 0x34, 0x01, 0x10]);
    expect(query.sublist(query.length - 4), [0x00, 0x21, 0x00, 0x01]);
  });

  test('eşleşen Node Status yanıtından bilgisayar adını güvenle okur', () {
    final response = NetbiosNodeStatusResponse.tryParse(
      _nodeStatusResponse(transactionId: transactionId),
      expectedTransactionId: transactionId,
    );

    expect(response?.computerName, 'DESKTOP-TEST');
  });

  test('yanlış işlem kimliği ve grup adı yanıtını reddeder', () {
    expect(
      NetbiosNodeStatusResponse.tryParse(
        _nodeStatusResponse(transactionId: transactionId),
        expectedTransactionId: 0x4321,
      ),
      isNull,
    );
    expect(
      NetbiosNodeStatusResponse.tryParse(
        _nodeStatusResponse(transactionId: transactionId, nameFlags: 0x8400),
        expectedTransactionId: transactionId,
      ),
      isNull,
    );
  });
}

List<int> _nodeStatusResponse({
  required int transactionId,
  int nameFlags = 0x0400,
}) {
  final name = 'DESKTOP-TEST'.codeUnits.toList()
    ..addAll(List<int>.filled(15 - 'DESKTOP-TEST'.length, 0x20));
  return [
    transactionId >> 8,
    transactionId & 0xff,
    0x85,
    0x00,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0xc0,
    0x0c,
    0x00,
    0x21,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x19,
    0x01,
    ...name,
    0x00,
    nameFlags >> 8,
    nameFlags & 0xff,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ];
}
