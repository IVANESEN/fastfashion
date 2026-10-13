import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Chip de filtro/selección.
///
/// * relleno: seleccionado = borgoña con texto blanco; reposo = rosa empolvado.
/// * contorno: seleccionado = tinta; reposo = blanco con borde.
class FfChip extends StatelessWidget {
  const FfChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlined = false,
    this.height = 40,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool outlined;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    if (outlined) {
      bg = selected ? AppColors.ink : AppColors.white;
      fg = selected ? AppColors.white : AppColors.wine;
      border = selected ? AppColors.ink : AppColors.outline;
    } else {
      bg = selected ? AppColors.primary : AppColors.blush;
      fg = selected ? AppColors.white : AppColors.primaryDeep;
      border = Colors.transparent;
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: BorderSide(color: border, width: outlined ? 2 : 0),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          // `Center(widthFactor: 1)` ajusta el ancho al texto; un `Container`
          // con `alignment` se estiraría a todo el ancho dentro de un Wrap.
          child: SizedBox(
            height: height,
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: height >= 40 ? 16 : 14,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    fontSize: height >= 40 ? 14 : 13,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta informativa no interactiva (sobre tarjetas borgoña o blancas).
class FfTag extends StatelessWidget {
  const FfTag(this.label, {this.onDark = true, super.key});

  final String label;

  /// `true` sobre fondo borgoña (blanco translúcido); `false` sobre blanco.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.18) : AppColors.blush,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Lato',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: onDark ? AppColors.white : AppColors.primaryDeep,
        ),
      ),
    );
  }
}
