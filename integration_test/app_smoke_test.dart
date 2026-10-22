import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';
import 'package:spy_dev_det/features/onboarding/application/onboarding_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana bölümler gerçek uygulama kabuğunda açılır', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialOnboardingCompletedProvider.overrideWithValue(true)],
        child: const SpyDevDetApp(),
      ),
    );
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
    expect(find.text('Görünüm modu'), findsOneWidget);
    expect(find.text('Renk teması'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
