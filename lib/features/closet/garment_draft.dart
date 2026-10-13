import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/imaging/image_tools.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/garment_category.dart';
import '../../domain/entities/garment_color.dart';
import '../../domain/entities/garment_style.dart';
import '../../domain/services/color_detector.dart';

typedef ColorDetectorFn = Future<ColorDetection?> Function(Uint8List bytes);

/// Borrador de una prenda en edición (agregar o modificar).
///
/// Concentra el estado del formulario para que las pantallas de alta y de
/// detalle compartan comportamiento: nombre automático, detección de color
/// y detección de cambios.
class GarmentDraft extends ChangeNotifier {
  GarmentDraft({Garment? initial, ColorDetectorFn? detector})
    : _initial = initial,
      _detector = detector ?? detectColorFromImage,
      name = TextEditingController(text: initial?.name ?? ''),
      category = initial?.category ?? GarmentCategory.top,
      style = initial?.style ?? GarmentStyle.casual,
      color = initial?.color ?? GarmentPalette.blue,
      existingImageUrl = initial?.imageUrl,
      _nameEdited = initial != null {
    if (initial == null) _applyAutoName();
  }

  final Garment? _initial;
  final ColorDetectorFn _detector;

  final TextEditingController name;
  GarmentCategory category;
  GarmentStyle style;
  GarmentColor color;

  /// Foto nueva elegida en esta sesión (aún no guardada).
  Uint8List? photoBytes;

  /// Foto ya guardada de una prenda existente.
  String? existingImageUrl;

  /// Color que la detección sacó de la última foto, si lo hubo.
  GarmentColor? detectedColor;
  bool detecting = false;
  bool _nameEdited;

  bool get isNew => _initial == null;
  bool get hasPhoto =>
      photoBytes != null || (existingImageUrl?.isNotEmpty ?? false);

  /// `true` si algo cambió respecto a la prenda original.
  bool get dirty {
    final g = _initial;
    if (g == null) return true;
    return name.text.trim() != g.name ||
        category != g.category ||
        style != g.style ||
        color != g.color ||
        photoBytes != null;
  }

  String get suggestedName => '${category.label} ${color.name.toLowerCase()}';

  void _applyAutoName() {
    if (_nameEdited) return;
    name.text = suggestedName;
  }

  void onNameTyped() {
    _nameEdited = true;
    notifyListeners();
  }

  void setCategory(GarmentCategory value) {
    category = value;
    _applyAutoName();
    notifyListeners();
  }

  void setStyle(GarmentStyle value) {
    style = value;
    notifyListeners();
  }

  void setColor(GarmentColor value) {
    color = value;
    _applyAutoName();
    notifyListeners();
  }

  /// Asigna la foto y detecta el color dominante.
  Future<void> setPhoto(Uint8List bytes) async {
    photoBytes = bytes;
    detecting = true;
    notifyListeners();
    try {
      final result = await _detector(bytes);
      if (result != null) {
        detectedColor = result.color;
        color = result.color;
        _applyAutoName();
      }
    } finally {
      detecting = false;
      notifyListeners();
    }
  }

  void removePhoto() {
    photoBytes = null;
    existingImageUrl = null;
    detectedColor = null;
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}
