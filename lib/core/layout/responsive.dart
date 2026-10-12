import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ancho útil de la columna de la app en pantallas grandes.
const double kMaxContentWidth = 480;

enum ScreenSize {
  /// Teléfonos pequeños (≤ 359 px de ancho, p. ej. iPhone SE 1.ª gen, 320 px).
  compact,

  /// Teléfonos habituales (360–599 px).
  regular,

  /// Tabletas y escritorio (≥ 600 px): la app se centra en una columna.
  wide,
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  ScreenSize get screenSize {
    final w = screenWidth;
    if (w < 360) return ScreenSize.compact;
    if (w < 600) return ScreenSize.regular;
    return ScreenSize.wide;
  }

  bool get isCompact => screenSize == ScreenSize.compact;

  /// Margen lateral de las pantallas.
  double get pagePadding => isCompact ? 16 : 20;

  /// Columnas de la cuadrícula del clóset según el ancho disponible.
  int closetColumns(double availableWidth) {
    if (availableWidth < 340) return 2;
    if (availableWidth < 560) return 2;
    return 3;
  }
}

/// Envoltorio raíz: en pantallas anchas centra la app en una columna de
/// [kMaxContentWidth] sobre fondo rosa empolvado, y le informa a los hijos el
/// ancho real para que `MediaQuery` y `LayoutBuilder` coincidan.
class AppFrame extends StatelessWidget {
  const AppFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= 600) return child;

    final width = kMaxContentWidth.clamp(0, media.size.width).toDouble();
    return ColoredBox(
      color: AppColors.blush,
      child: Center(
        child: SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F2A0A12),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: MediaQuery(
              data: media.copyWith(size: Size(width, media.size.height)),
              child: ClipRect(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
