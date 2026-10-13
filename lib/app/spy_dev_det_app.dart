import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/scan/presentation/scan_screen.dart';

class SpyDevDetApp extends StatelessWidget {
  const SpyDevDetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpyDevDet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF155E75),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const ScanScreen(),
    );
  }
}
