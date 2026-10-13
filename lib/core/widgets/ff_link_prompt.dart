import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Frase con acción al final ("¿Ya tienes cuenta? **Inicia sesión**").
///
/// Envuelve a varias líneas en pantallas angostas o con texto grande y
/// mantiene un objetivo táctil de al menos 48 px.
class FfLinkPrompt extends StatelessWidget {
  const FfLinkPrompt({
    required this.prompt,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$prompt $action',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text.rich(
                TextSpan(
                  text: '$prompt ',
                  style: AppText.caption.copyWith(fontSize: 14),
                  children: [
                    TextSpan(
                      text: action,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
