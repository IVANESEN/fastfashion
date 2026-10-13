import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/garment_illustration.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/outfit.dart';

/// Composición del outfit: la camisa grande a la izquierda y el resto de las
/// prendas apiladas a la derecha (pantalón, zapatos y chaqueta si la hay).
class OutfitBoard extends StatelessWidget {
  const OutfitBoard({required this.proposal, this.height = 250, super.key});

  final OutfitProposal proposal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final right = <Garment>[proposal.bottom, ?proposal.shoes, ?proposal.jacket];
    // Con la prenda grande a la izquierda, la columna derecha se reparte en 2–3.
    return SizedBox(
      height: right.length > 2 ? height + 40 : height,
      child: Row(
        children: [
          Expanded(child: GarmentTile(garment: proposal.top, large: true)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < right.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Expanded(child: GarmentTile(garment: right[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Casilla blanca con la prenda (foto o silueta) y su nombre.
class GarmentTile extends StatelessWidget {
  const GarmentTile({required this.garment, this.large = false, super.key});

  final Garment garment;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${garment.category.label}: ${garment.name}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: garment.hasPhoto
                      ? GarmentVisual(garment: garment, radius: 12)
                      : FittedBox(
                          child: GarmentVisual(garment: garment, size: 120),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                garment.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(
                  fontSize: large ? 13 : 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
