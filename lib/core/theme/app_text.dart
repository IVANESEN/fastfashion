import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala tipográfica: Poppins para títulos y botones, Lato para cuerpo.
abstract final class AppText {
  static const _poppins = 'Poppins';
  static const _lato = 'Lato';

  /// Poppins Bold 30 · títulos de pantalla.
  static const h1 = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 1.15,
    letterSpacing: -0.6,
    color: AppColors.ink,
  );

  /// Poppins Bold 22 · subtítulos.
  static const h2 = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  /// Poppins Bold 38 · titular de bienvenida.
  static const display = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w700,
    fontSize: 38,
    height: 1.05,
    letterSpacing: -1.1,
    color: AppColors.ink,
  );

  /// Poppins SemiBold 16 · títulos de sección.
  static const title = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.3,
    color: AppColors.ink,
  );

  /// Poppins SemiBold 15 · botones.
  static const button = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.2,
  );

  /// Lato Regular 15 · cuerpo.
  static const body = TextStyle(
    fontFamily: _lato,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.45,
    color: AppColors.ink,
  );

  /// Lato Bold 14 · etiquetas de campos y valores.
  static const label = TextStyle(
    fontFamily: _lato,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.3,
    color: AppColors.ink,
  );

  /// Lato Regular 13 · apoyos y descripciones.
  static const caption = TextStyle(
    fontFamily: _lato,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.4,
    color: AppColors.wine,
  );

  /// Lato Bold 12 en mayúsculas · "TU OUTFIT DE HOY".
  static const overline = TextStyle(
    fontFamily: _lato,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    height: 1.3,
    letterSpacing: 0.96,
    color: AppColors.wine,
  );
}
