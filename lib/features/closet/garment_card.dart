import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/garment_illustration.dart';
import '../../domain/entities/garment.dart';

/// Tarjeta de prenda del clóset (silueta o foto + nombre + estilo).
class GarmentCard extends StatelessWidget {
  const GarmentCard({
    required this.garment,
    required this.onTap,
    this.alt = false,
    super.key,
  });

  final Garment garment;
  final VoidCallback onTap;

  /// Alterna entre dos tonos de rosa para dar ritmo a la cuadrícula.
  final bool alt;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${garment.name}, ${garment.category.label}, ${garment.style.label}, '
          '${garment.color.name}',
      excludeSemantics: true,
      child: Material(
        color: alt ? AppColors.blushSoft : AppColors.blush,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: garment.hasPhoto
                        ? GarmentVisual(garment: garment, radius: 16)
                        : FractionallySizedBox(
                            heightFactor: 0.9,
                            child: FittedBox(
                              child: GarmentVisual(garment: garment, size: 108),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  garment.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(fontSize: 13),
                ),
                Text(
                  garment.style.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
