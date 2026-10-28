import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/network_text_sanitizer.dart';

void main() {
  test('kontrol, görünmez ve çift yönlü metin karakterlerini kaldırır', () {
    final value = NetworkTextSanitizer.sanitize(
      'Salon\u0000\u0085\u200BKamera\u202Eabc\u2066\u00ad\u2028',
      maxRunes: 80,
    );

    expect(value, 'SalonKameraabc');
  });

  test('Unicode metni kod noktası sınırında kısaltır', () {
    final value = NetworkTextSanitizer.sanitize('A😀B', maxRunes: 2);

    expect(value, 'A😀');
    expect(value.runes, hasLength(2));
  });

  test('geçersiz uzunluk sınırını reddeder', () {
    expect(
      () => NetworkTextSanitizer.sanitize('test', maxRunes: 0),
      throwsRangeError,
    );
  });
}
