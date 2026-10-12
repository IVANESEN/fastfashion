import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum FfButtonStyle {
  /// Borgoña sólido · acción principal de la pantalla.
  primary,

  /// Tinta sólida · "Usar este outfit".
  ink,

  /// Borde borgoña sobre blanco · acción secundaria.
  outline,

  /// Rosa empolvado · acción terciaria.
  tonal,

  /// Blanco con texto borgoña · sobre fondos borgoña.
  onPrimary,
}

/// Botón píldora del sistema. Alto mínimo 48 px para cumplir objetivos táctiles.
class FfButton extends StatelessWidget {
  const FfButton({
    required this.label,
    required this.onPressed,
    this.style = FfButtonStyle.primary,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.height = 52,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final FfButtonStyle style;
  final IconData? icon;
  final bool expand;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, borderColor) = switch (style) {
      FfButtonStyle.primary => (
        AppColors.primary,
        AppColors.white,
        Colors.transparent,
      ),
      FfButtonStyle.ink => (AppColors.ink, AppColors.white, Colors.transparent),
      FfButtonStyle.outline => (
        AppColors.white,
        AppColors.primary,
        AppColors.primary,
      ),
      FfButtonStyle.tonal => (
        AppColors.blush,
        AppColors.primaryDeep,
        Colors.transparent,
      ),
      FfButtonStyle.onPrimary => (
        AppColors.white,
        AppColors.primary,
        Colors.transparent,
      ),
    };

    final enabled = onPressed != null && !loading;
    final content = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button.copyWith(color: fg),
                ),
              ),
            ],
          );

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: BorderSide(
              color: borderColor,
              width: style == FfButtonStyle.outline ? 2 : 0,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: enabled ? onPressed : null,
            child: Container(
              height: height,
              constraints: const BoxConstraints(minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
