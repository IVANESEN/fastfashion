import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'ff_button.dart';

/// Estado vacío o de error con ícono, mensaje y acciones opcionales.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 34, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppText.h2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppText.caption.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 20),
                FfButton(label: actionLabel!, onPressed: onAction),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: 10),
                FfButton(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  style: FfButtonStyle.tonal,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
