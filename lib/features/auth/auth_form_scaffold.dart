import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/brand_wordmark.dart';

/// Estructura común de Iniciar sesión / Crear cuenta: marca, título,
/// contenido desplazable (cabe con teclado abierto) y pie con acciones.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.leading,
    this.error,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? error;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 360 ? 16.0 : 24.0;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ?leading,
                      const SizedBox(width: 12),
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: BrandWordmark(size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(title, style: AppText.h1),
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, style: AppText.caption.copyWith(fontSize: 15)),
                  const SizedBox(height: 24),
                  if (error != null) ...[
                    _ErrorBanner(message: error!),
                    const SizedBox(height: 16),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: AppText.body.copyWith(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
