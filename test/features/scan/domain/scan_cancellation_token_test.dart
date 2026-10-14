import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/features/scan/domain/scan_cancellation_token.dart';

void main() {
  test('iptal dinleyicilerini yalnızca bir kez çalıştırır', () {
    final token = ScanCancellationToken();
    var callCount = 0;
    token.addCancelListener(() => callCount++);

    token.cancel();
    token.cancel();

    expect(token.isCancelled, isTrue);
    expect(callCount, 1);
  });

  test('iptalden sonra eklenen dinleyiciyi hemen çalıştırır', () {
    final token = ScanCancellationToken()..cancel();
    var wasCalled = false;

    token.addCancelListener(() => wasCalled = true);

    expect(wasCalled, isTrue);
  });
}
