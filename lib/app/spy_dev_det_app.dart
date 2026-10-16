import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/scan/presentation/scan_screen.dart';

class SpyDevDetApp extends StatelessWidget {
  const SpyDevDetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpyDevDet',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const ScanScreen(),
    );
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF155E75),
      brightness: brightness,
    ),
    useMaterial3: true,
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
  );
}
