import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/services/color_detector.dart';

/// Detecta el color dominante de una foto ya codificada (JPEG/PNG/WebP).
///
/// Reduce la imagen a ~96 px de ancho antes de analizarla, así que es
/// barato incluso con fotos de cámara de 12 MP. Devuelve `null` si el
/// archivo no se puede decodificar.
Future<ColorDetection?> detectColorFromImage(Uint8List bytes) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(bytes, targetWidth: 96);
    final frame = await codec.getNextFrame();
    image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    return detectDominantColor(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      image.width,
      image.height,
    );
  } on Object {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}
