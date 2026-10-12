import 'package:flutter/material.dart';

import '../../domain/entities/garment_color.dart';
import '../theme/app_colors.dart';

/// Círculo de color seleccionable (filtro "Por color" y selector de color).
class ColorDot extends StatelessWidget {
  const ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.size = 44,
    super.key,
  });

  final GarmentColor color;
  final bool selected;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fill = Color(color.value);
    // Los tonos muy claros se pierden sobre blanco: les damos borde.
    final needsBorder = fill.computeLuminance() > 0.7;

    return Semantics(
      button: true,
      selected: selected,
      label: color.name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(selected ? 3 : 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    border: needsBorder
                        ? Border.all(color: AppColors.outline)
                        : null,
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: size * 0.4,
                          color: fill.computeLuminance() > 0.5
                              ? AppColors.ink
                              : AppColors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
