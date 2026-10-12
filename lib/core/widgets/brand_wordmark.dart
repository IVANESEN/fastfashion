import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logotipo tipográfico: `fastfashion` + punto en tinta.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    this.size = 26,
    this.color = AppColors.primary,
    this.dotColor = AppColors.ink,
    super.key,
  });

  final double size;
  final Color color;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'FastFashion',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'fastfashion',
              style: TextStyle(color: color),
            ),
            TextSpan(
              text: '.',
              style: TextStyle(color: dotColor),
            ),
          ],
        ),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: size,
          letterSpacing: -size * 0.04,
          height: 1,
        ),
      ),
    );
  }
}
