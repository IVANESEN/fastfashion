import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Botón circular de 44–48 px (volver, perfil, cerrar).
class FfIconButton extends StatelessWidget {
  const FfIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background = AppColors.blush,
    this.foreground = AppColors.ink,
    this.size = 44,
    super.key,
  });

  final IconData icon;

  /// Texto accesible (lector de pantalla y tooltip).
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, size: 22, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar circular con la inicial del usuario.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    required this.initial,
    this.size = 48,
    this.onTap,
    super.key,
  });

  final String initial;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Perfil',
      excludeSemantics: true,
      child: Material(
        color: AppColors.blush,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Text(
                initial,
                style: AppText.title.copyWith(
                  color: AppColors.primary,
                  fontSize: size * 0.38,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de sección en mayúsculas ("CATEGORÍA").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppText.overline);
  }
}
