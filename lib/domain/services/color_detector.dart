import 'dart:typed_data';

import '../entities/garment_color.dart';

/// Resultado de detectar el color dominante de una foto.
class ColorDetection {
  const ColorDetection(this.color, this.confidence);

  final GarmentColor color;

  /// 0–1: fracción de píxeles de la prenda que caen en ese color.
  final double confidence;
}

/// Detecta el color dominante de una prenda a partir de píxeles RGBA.
///
/// Heurística: estima el fondo con el borde de la imagen, lo descarta si es
/// uniforme (foto de producto sobre pared/sábana) y toma el cubo de color más
/// poblado del centro. Después lo ajusta al color más cercano de la paleta.
///
/// No usa red ni modelos: corre en el dispositivo y es determinista.
ColorDetection? detectDominantColor(Uint8List rgba, int width, int height) {
  if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
    return null;
  }

  int r(int x, int y) => rgba[(y * width + x) * 4];
  int g(int x, int y) => rgba[(y * width + x) * 4 + 1];
  int b(int x, int y) => rgba[(y * width + x) * 4 + 2];
  int a(int x, int y) => rgba[(y * width + x) * 4 + 3];

  // --- Fondo: promedio del anillo exterior (≈ 6 % del lado) ---------------
  final ring = (width < height ? width : height) ~/ 16 + 1;
  var bgR = 0, bgG = 0, bgB = 0, bgN = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final onRing =
          x < ring || y < ring || x >= width - ring || y >= height - ring;
      if (!onRing || a(x, y) < 128) continue;
      bgR += r(x, y);
      bgG += g(x, y);
      bgB += b(x, y);
      bgN++;
    }
  }
  final hasBackground = bgN > 0;
  final avgR = hasBackground ? bgR ~/ bgN : 0;
  final avgG = hasBackground ? bgG ~/ bgN : 0;
  final avgB = hasBackground ? bgB ~/ bgN : 0;

  // ¿El borde es uniforme? (desviación media baja) → es un fondo real.
  var dev = 0;
  if (hasBackground) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final onRing =
            x < ring || y < ring || x >= width - ring || y >= height - ring;
        if (!onRing || a(x, y) < 128) continue;
        dev +=
            (r(x, y) - avgR).abs() +
            (g(x, y) - avgG).abs() +
            (b(x, y) - avgB).abs();
      }
    }
  }
  final uniformBackground = hasBackground && (dev / (bgN * 3)) < 22;

  // --- Histograma de la zona central ---------------------------------------
  Map<int, _Bucket> histogram({required bool skipBackground}) {
    final buckets = <int, _Bucket>{};
    final x0 = width ~/ 10, x1 = width - width ~/ 10;
    final y0 = height ~/ 10, y1 = height - height ~/ 10;
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        if (a(x, y) < 128) continue;
        final pr = r(x, y), pg = g(x, y), pb = b(x, y);
        if (skipBackground) {
          final d = (pr - avgR).abs() + (pg - avgG).abs() + (pb - avgB).abs();
          if (d < 60) continue;
        }
        // 4 bits por canal (16 niveles) → 4096 cubos.
        final key = ((pr >> 4) << 8) | ((pg >> 4) << 4) | (pb >> 4);
        final bucket = buckets.putIfAbsent(key, _Bucket.new);
        bucket.add(pr, pg, pb);
      }
    }
    return buckets;
  }

  var buckets = histogram(skipBackground: uniformBackground);
  var total = buckets.values.fold<int>(0, (s, e) => s + e.count);
  final areaCentral =
      (width - 2 * (width ~/ 10)) * (height - 2 * (height ~/ 10));

  // Si al quitar el fondo casi no queda nada, la prenda *es* del color del
  // fondo (p. ej. camiseta blanca sobre pared blanca): usamos todo.
  if (uniformBackground && total < areaCentral * 0.04) {
    buckets = histogram(skipBackground: false);
    total = buckets.values.fold<int>(0, (s, e) => s + e.count);
  }
  if (total == 0) return null;

  // Un cubo vecino cuenta a favor del dominante (tolera sombras y arrugas).
  _Bucket? best;
  var bestCount = 0;
  for (final entry in buckets.entries) {
    final key = entry.key;
    final kr = key >> 8, kg = (key >> 4) & 0xF, kb = key & 0xF;
    var count = 0;
    for (final other in buckets.entries) {
      final ok = other.key;
      final dr = ((ok >> 8) - kr).abs();
      final dg = (((ok >> 4) & 0xF) - kg).abs();
      final db = ((ok & 0xF) - kb).abs();
      if (dr <= 1 && dg <= 1 && db <= 1) count += other.value.count;
    }
    if (count > bestCount) {
      bestCount = count;
      best = entry.value;
    }
  }
  if (best == null) return null;

  final argb = 0xFF000000 | (best.r << 16) | (best.g << 8) | best.b;
  return ColorDetection(GarmentPalette.nearest(argb), bestCount / total);
}

class _Bucket {
  int count = 0;
  int _r = 0, _g = 0, _b = 0;

  void add(int r, int g, int b) {
    count++;
    _r += r;
    _g += g;
    _b += b;
  }

  int get r => _r ~/ count;
  int get g => _g ~/ count;
  int get b => _b ~/ count;
}
