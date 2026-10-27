import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/history/data/scan_history_codec.dart';
import 'package:spy_dev_det/features/scan/domain/scan_report.dart';

void main() {
  test('eski birleşik keşif kaydını ayrı NetBIOS alanıyla uyumlu okur', () {
    final oldPayload = jsonEncode({
      'onvif': {'phase': 'completed', 'deviceCount': 2, 'elapsedMillis': 500},
    });

    final methods = const ScanHistoryCodec().decodeMethods(oldPayload);

    expect(
      methods[DiscoveryMethod.onvif]?.phase,
      DiscoveryMethodPhase.completed,
    );
    expect(
      methods[DiscoveryMethod.netbios]?.phase,
      DiscoveryMethodPhase.completed,
    );
    expect(
      methods[DiscoveryMethod.netbios]?.userMessage,
      contains('ayrı raporlanmadan önce'),
    );
  });
}
