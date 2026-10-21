import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana bölümler gerçek uygulama kabuğunda açılır', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpyDevDetApp()));
    await tester.pumpAndSettle();

    expect(find.text('Yerel ağı tara'), findsOneWidget);

    await tester.tap(find.text('Cihazlar'));
    await tester.pumpAndSettle();
    expect(find.text('Cihazlarda ara'), findsOneWidget);
    expect(find.textContaining('Kayıtlı cihaz profilleri'), findsOneWidget);

    await tester.tap(find.text('Ağlar'));
    await tester.pumpAndSettle();
    expect(find.text('Ağ profilleri'), findsOneWidget);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Tarama geçmişi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
