/// Color con nombre de la paleta de prendas.
///
/// El valor se guarda como ARGB entero para mantener el dominio libre de
/// `dart:ui`. La UI lo convierte con `Color(value)`.
class GarmentColor {
  const GarmentColor(this.name, this.value, {this.isNeutral = false});

  final String name;
  final int value;

  /// Neutros (negro, blanco, beige, gris, marino) combinan con casi todo.
  final bool isNeutral;

  int get red => (value >> 16) & 0xFF;
  int get green => (value >> 8) & 0xFF;
  int get blue => value & 0xFF;

  @override
  bool operator ==(Object other) =>
      other is GarmentColor && other.name == name && other.value == value;

  @override
  int get hashCode => Object.hash(name, value);
}

/// Paleta cerrada de colores reconocibles. Es la fuente de verdad para el
/// selector de color, el detector de color de la foto y el asistente.
abstract final class GarmentPalette {
  static const blue = GarmentColor('Azul', 0xFF3B6FD8);
  static const navy = GarmentColor('Azul marino', 0xFF34507A, isNeutral: true);
  static const black = GarmentColor('Negro', 0xFF24212B, isNeutral: true);
  static const white = GarmentColor('Blanco', 0xFFF4F2F0, isNeutral: true);
  static const beige = GarmentColor('Beige', 0xFFD9C3A0, isNeutral: true);
  static const gray = GarmentColor('Gris', 0xFF8C8794, isNeutral: true);
  static const brown = GarmentColor('Café', 0xFF7A4A2B);
  static const lilac = GarmentColor('Lila', 0xFFC9A7EB);
  static const red = GarmentColor('Rojo', 0xFFC8323C);
  static const burgundy = GarmentColor('Borgoña', 0xFF800020);
  static const pink = GarmentColor('Rosa', 0xFFE8A0B5);
  static const orange = GarmentColor('Naranja', 0xFFE0803A);
  static const yellow = GarmentColor('Amarillo', 0xFFE8C547);
  static const green = GarmentColor('Verde', 0xFF3F8F5B);
  static const olive = GarmentColor('Verde oliva', 0xFF6B7A3A);
  static const camel = GarmentColor('Camel', 0xFFC58B5C);

  static const all = <GarmentColor>[
    blue,
    navy,
    black,
    white,
    beige,
    gray,
    brown,
    lilac,
    red,
    burgundy,
    pink,
    orange,
    yellow,
    green,
    olive,
    camel,
  ];

  /// Los seis colores del filtro rápido "Por color" del clóset.
  static const quickFilter = <GarmentColor>[
    blue,
    black,
    beige,
    white,
    lilac,
    brown,
  ];

  static GarmentColor byName(String name) {
    return all.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => nearest(0xFF808080),
    );
  }

  static GarmentColor fromValue(int value, {String? name}) {
    if (name != null) {
      for (final c in all) {
        if (c.name == name) return c;
      }
    }
    return nearest(value);
  }

  /// Color de la paleta más cercano a un RGB arbitrario (distancia "redmean",
  /// una aproximación perceptual barata y suficiente para ropa).
  static GarmentColor nearest(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    var best = all.first;
    var bestDistance = double.infinity;
    for (final c in all) {
      final rMean = (r + c.red) / 2;
      final dr = (r - c.red).toDouble();
      final dg = (g - c.green).toDouble();
      final db = (b - c.blue).toDouble();
      final d =
          (2 + rMean / 256) * dr * dr +
          4 * dg * dg +
          (2 + (255 - rMean) / 256) * db * db;
      if (d < bestDistance) {
        bestDistance = d;
        best = c;
      }
    }
    return best;
  }
}
