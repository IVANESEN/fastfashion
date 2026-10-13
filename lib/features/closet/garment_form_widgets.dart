import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/color_dot.dart';
import '../../core/widgets/ff_chip.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../core/widgets/garment_illustration.dart';
import '../../domain/entities/garment_category.dart';
import '../../domain/entities/garment_color.dart';
import '../../domain/entities/garment_style.dart';
import 'garment_draft.dart';
import 'photo_picker.dart';

Widget _photoError(BuildContext context, Object error, StackTrace? stack) {
  return const Center(
    child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.wine),
  );
}

/// Panel con la foto (o la silueta) de la prenda y el botón de cámara.
class GarmentPhotoPanel extends StatelessWidget {
  const GarmentPhotoPanel({
    required this.draft,
    required this.onPickPhoto,
    super.key,
  });

  final GarmentDraft draft;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final color = Color(draft.color.value);

    Widget visual;
    final bytes = draft.photoBytes;
    final url = draft.existingImageUrl;
    if (bytes != null) {
      visual = Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: _photoError,
      );
    } else if (url != null && url.startsWith('data:')) {
      visual = Image.memory(
        base64Decode(url.substring(url.indexOf(',') + 1)),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: _photoError,
      );
    } else if (url != null && url.startsWith('http')) {
      visual = Image.network(url, fit: BoxFit.cover, errorBuilder: _photoError);
    } else {
      visual = Center(
        child: FractionallySizedBox(
          widthFactor: 0.6,
          heightFactor: 0.6,
          child: FittedBox(
            child: GarmentIllustration(
              category: draft.category,
              color: color,
              size: 170,
            ),
          ),
        ),
      );
    }

    final detected = draft.detectedColor;
    final String chipText;
    if (draft.detecting) {
      chipText = 'Detectando color…';
    } else if (detected != null) {
      chipText = 'Color detectado: ${detected.name.toLowerCase()}';
    } else {
      chipText = 'Sube una foto y detectamos el color';
    }

    return AspectRatio(
      aspectRatio: 1.25,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: AppColors.blush,
          child: Stack(
            fit: StackFit.expand,
            children: [
              visual,
              Positioned(
                top: 14,
                left: 14,
                right: 70,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            chipText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: FfIconButton(
                  icon: Icons.photo_camera_outlined,
                  label: draft.hasPhoto
                      ? 'Cambiar foto'
                      : 'Tomar o elegir foto',
                  background: AppColors.ink,
                  foreground: AppColors.white,
                  size: 48,
                  onPressed: onPickPhoto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campos editables: nombre, categoría, estilo y color.
class GarmentFields extends StatelessWidget {
  const GarmentFields({required this.draft, super.key});

  final GarmentDraft draft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Nombre'),
        const SizedBox(height: 8),
        TextField(
          controller: draft.name,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 40,
          onChanged: (_) => draft.onNameTyped(),
          style: AppText.body,
          decoration: const InputDecoration(
            hintText: 'Ej. Camisa oxford azul',
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Categoría'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in GarmentCategory.values)
              FfChip(
                label: c.label,
                height: 44,
                selected: draft.category == c,
                onTap: () => draft.setCategory(c),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel('Estilo'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in GarmentStyle.values)
              FfChip(
                label: s.label,
                height: 44,
                selected: draft.style == s,
                onTap: () => draft.setStyle(s),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _ColorTile(draft: draft),
      ],
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({required this.draft});

  final GarmentDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(draft.color.value),
              border: Border.all(color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color principal',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  draft.color.name,
                  style: AppText.label.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 48),
              foregroundColor: AppColors.primary,
              textStyle: AppText.label,
            ),
            onPressed: () async {
              final picked = await showColorPickerSheet(
                context,
                current: draft.color,
              );
              if (picked != null) draft.setColor(picked);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

/// Hoja inferior para elegir un color de la paleta.
Future<GarmentColor?> showColorPickerSheet(
  BuildContext context, {
  required GarmentColor current,
}) {
  return showModalBottomSheet<GarmentColor>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elige el color', style: AppText.h2),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final c in GarmentPalette.all)
                  SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        ColorDot(
                          color: c,
                          size: 52,
                          selected: c == current,
                          onTap: () => Navigator.of(context).pop(c),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Hoja inferior con las fuentes de foto. Devuelve `null` si se cierra.
Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  required bool hasPhoto,
  VoidCallback? onRemove,
}) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
            if (hasPhoto && onRemove != null)
              ListTile(
                minTileHeight: 56,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Quitar foto',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  onRemove();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Atajo: pide la fuente y, si hay foto, la aplica al borrador.
Future<void> pickPhotoInto(
  BuildContext context,
  GarmentDraft draft,
  PhotoPicker picker,
) async {
  final source = await showPhotoSourceSheet(
    context,
    hasPhoto: draft.hasPhoto,
    onRemove: draft.removePhoto,
  );
  if (source == null) return;
  final Uint8List? bytes;
  try {
    bytes = await picker.pick(source);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pudimos abrir la cámara o la galería.')),
    );
    return;
  }
  if (bytes != null) await draft.setPhoto(bytes);
}
