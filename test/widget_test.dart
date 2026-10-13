import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spy_dev_det/app/spy_dev_det_app.dart';

void main() {
  testWidgets('demo tarama cihazları aşamalı olarak gösterir', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpyDevDetApp()));

    expect(find.text('Demo taramayı başlat'), findsOneWidget);
    expect(find.text('Bulunan cihazlar (0)'), findsOneWidget);

    await tester.tap(find.text('Demo taramayı başlat'));
    await tester.pump();

    expect(find.text('Taramayı durdur'), findsOneWidget);
    expect(find.text('Demo cihazlar aranıyor'), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      await tester.pump(const Duration(milliseconds: 310));
    }

    expect(find.text('Demo yönlendirici'), findsOneWidget);
    expect(find.text('Demo bilgisayar'), findsOneWidget);
    expect(find.text('Bulunan cihazlar (3)'), findsOneWidget);
    expect(find.text('Demo tarama tamamlandı'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Bilinmeyen demo cihaz'), findsOneWidget);
  });

  testWidgets('devam eden demo tarama iptal edilebilir', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpyDevDetApp()));

    await tester.tap(find.text('Demo taramayı başlat'));
    await tester.pump();
    await tester.tap(find.text('Taramayı durdur'));
    await tester.pump();

    expect(find.text('Tarama iptal edildi'), findsOneWidget);
    expect(find.text('Demo taramayı başlat'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 310));
  });
}
