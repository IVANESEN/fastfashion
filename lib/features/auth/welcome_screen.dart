import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/garment_illustration.dart';
import '../../domain/entities/garment_category.dart';

/// 01 · Bienvenida: propuesta de valor y acceso.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 360 ? 20.0 : 24.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 32, pad, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BrandWordmark(
                            color: AppColors.white,
                            dotColor: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Expanded(child: _Mosaic()),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            'Deja de pensar qué ponerte.',
                            style: AppText.display.copyWith(
                              color: AppColors.white,
                              fontSize: constraints.maxWidth < 360 ? 31 : 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sube tu ropa una vez. Cada mañana te damos un '
                          'outfit según el clima, la ocasión y tu estilo, '
                          'en menos de 5 segundos.',
                          style: AppText.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.92),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        FfButton(
                          label: 'Crear mi clóset',
                          style: FfButtonStyle.onPrimary,
                          height: 56,
                          onPressed: () => context.go(AppRoutes.signup),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: AppColors.white,
                            textStyle: AppText.label.copyWith(fontSize: 15),
                          ),
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('Ya tengo cuenta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Mosaico de tres prendas: camisa grande a la izquierda, pantalón y zapatos
/// apilados a la derecha.
class _Mosaic extends StatelessWidget {
  const _Mosaic();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 220, maxHeight: 360),
      child: const Row(
        children: [
          Expanded(
            child: _Tile(
              background: AppColors.blush,
              category: GarmentCategory.top,
              color: AppColors.ink,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _Tile(
                    background: AppColors.white,
                    category: GarmentCategory.bottom,
                    color: Color(0xFFD9C3A0),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: _Tile(
                    background: AppColors.primaryDeep,
                    category: GarmentCategory.shoes,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.background,
    required this.category,
    required this.color,
  });

  final Color background;
  final GarmentCategory category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.62,
          heightFactor: 0.62,
          child: FittedBox(
            child: GarmentIllustration(
              category: category,
              color: color,
              size: 120,
            ),
          ),
        ),
      ),
    );
  }
}
