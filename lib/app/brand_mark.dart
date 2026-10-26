import 'package:flutter/material.dart';

class SpyDevDetBrandMark extends StatelessWidget {
  const SpyDevDetBrandMark({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Image.asset(
          'assets/branding/app_mark.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
