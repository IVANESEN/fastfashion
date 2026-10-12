import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../domain/entities/garment.dart';
import '../../domain/entities/garment_category.dart';
import '../theme/app_colors.dart';

/// Siluetas vectoriales del sistema de marca (viewBox 100 × 100).
abstract final class _Silhouettes {
  static final top = parseSvgPathData(
    'M30 18 L42 12 Q50 22 58 12 L70 18 L88 34 L77 46 L70 40 L70 88 L30 88 L30 40 L23 46 L12 34 Z',
  );
  static final bottom = parseSvgPathData(
    'M30 10 L70 10 L75 90 L56 90 L50 38 L44 90 L25 90 Z',
  );
  static final shoes = parseSvgPathData(
    'M10 64 L10 42 Q22 43 30 36 L45 50 Q62 56 82 58 Q92 60 92 70 L92 76 L10 76 Z',
  );
  static final jacket = parseSvgPathData(
    'M26 16 L40 10 L50 20 L60 10 L74 16 L94 44 L84 54 L74 46 L74 90 L26 90 L26 46 L16 54 L6 44 Z',
  );
  // Cierre central de la chaqueta.
  static final zipper = parseSvgPathData('M50 20 L50 90');

  static Path of(GarmentCategory c) => switch (c) {
    GarmentCategory.top => top,
    GarmentCategory.bottom => bottom,
    GarmentCategory.shoes => shoes,
    GarmentCategory.jacket => jacket,
  };
}

/// Dibuja la silueta de una categoría rellena con [color].
class GarmentIllustration extends StatelessWidget {
  const GarmentIllustration({
    required this.category,
    required this.color,
    this.size = 100,
    this.semanticLabel,
    super.key,
  });

  final GarmentCategory category;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SilhouettePainter(category, color)),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: paint);
    return Semantics(label: semanticLabel, image: true, child: paint);
  }
}

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter(this.category, this.color);

  final GarmentCategory category;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final path = _Silhouettes.of(category);
    canvas.drawPath(path, Paint()..color = color);

    // Prendas claras necesitan un contorno más marcado para no perderse.
    final outlineAlpha = color.computeLuminance() > 0.6 ? 0.30 : 0.18;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink.withValues(alpha: outlineAlpha);
    canvas.drawPath(path, stroke);

    if (category == GarmentCategory.jacket) {
      canvas.drawPath(_Silhouettes.zipper, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) =>
      old.category != category || old.color != color;
}

/// Foto de la prenda si existe; si no, su silueta con el color de la prenda.
class GarmentVisual extends StatefulWidget {
  const GarmentVisual({
    required this.garment,
    this.size = 100,
    this.fit = BoxFit.cover,
    this.radius = 16,
    super.key,
  });

  final Garment garment;

  /// Lado del cuadro donde se dibuja la silueta (la foto llena su contenedor).
  final double size;
  final BoxFit fit;
  final double radius;

  @override
  State<GarmentVisual> createState() => _GarmentVisualState();
}

class _GarmentVisualState extends State<GarmentVisual> {
  Uint8List? _bytes;
  String? _bytesFor;

  Uint8List? _decode(String? url) {
    if (url == null || !url.startsWith('data:')) return null;
    if (_bytesFor == url) return _bytes;
    final comma = url.indexOf(',');
    if (comma < 0) return null;
    try {
      _bytes = base64Decode(url.substring(comma + 1));
      _bytesFor = url;
    } on FormatException {
      _bytes = null;
    }
    return _bytes;
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.garment;
    final illustration = GarmentIllustration(
      category: g.category,
      color: Color(g.color.value),
      size: widget.size,
    );

    final url = g.imageUrl;
    if (url == null || url.isEmpty) return illustration;

    final bytes = _decode(url);
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes, fit: widget.fit, gaplessPlayback: true);
    } else if (url.startsWith('http')) {
      image = Image.network(
        url,
        fit: widget.fit,
        errorBuilder: (_, _, _) => Center(child: illustration),
      );
    } else {
      return illustration;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox.expand(child: image),
    );
  }
}
