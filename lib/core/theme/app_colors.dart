import 'package:flutter/material.dart';

/// Paleta del sistema de marca FastFashion.
///
/// Regla del diseño: el borgoña solo marca lo principal de cada pantalla;
/// todo lo demás va en blanco y rosa empolvado para que la ropa destaque.
abstract final class AppColors {
  /// Borgoña · primario.
  static const primary = Color(0xFF800020);

  /// Borgoña profundo · hover / pressed.
  static const primaryDeep = Color(0xFF5C0018);

  /// Tinta · texto principal y botón oscuro.
  static const ink = Color(0xFF2A0A12);

  /// Rosa empolvado · superficies.
  static const blush = Color(0xFFF8ECEE);

  /// Variante más clara de las superficies (tarjetas alternas).
  static const blushSoft = Color(0xFFFAF5F6);

  /// Gris vino · texto secundario.
  static const wine = Color(0xFF6B4F55);

  /// Gris vino para íconos/etiquetas inactivas de la barra inferior.
  static const wineMuted = Color(0xFF75585E);

  /// Separadores y bordes sutiles.
  static const border = Color(0xFFF1E4E7);

  /// Borde de chips "outline".
  static const outline = Color(0xFFE8D5DA);

  /// Pista apagada de los interruptores.
  static const trackOff = Color(0xFFDCC8CD);

  static const white = Color(0xFFFFFFFF);

  /// Errores de formulario. Distinto del borgoña para no confundir con acción.
  static const error = Color(0xFFB3261E);

  static const success = Color(0xFF2E7D4F);
}
