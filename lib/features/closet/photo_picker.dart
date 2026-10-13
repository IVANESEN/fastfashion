import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Obtiene la foto de una prenda. Interfaz para poder sustituirla en pruebas.
abstract interface class PhotoPicker {
  /// Devuelve los bytes (JPEG reducido) o `null` si el usuario canceló.
  Future<Uint8List?> pick(PhotoSource source);
}

/// Implementación real con `image_picker` (cámara o galería, también en web).
///
/// Reduce la foto a 800 px y calidad 78 para que quepa en el almacenamiento
/// del navegador y suba rápido.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 78,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
