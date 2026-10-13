import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format/dates.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ff_switch.dart';
import '../../domain/entities/reminder_settings.dart';
import 'reminders_controller.dart';

/// 06 · Recordatorios: hora, días y tipos de aviso.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _editTime(
    BuildContext context,
    RemindersController controller,
  ) async {
    final s = controller.settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
      helpText: 'Hora de tu outfit',
    );
    if (picked != null) {
      await controller.setTime(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RemindersController>();
    final s = controller.settings;
    final pad = context.pagePadding;
    final next = controller.nextFire;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 24),
            children: [
              Semantics(
                header: true,
                child: const Text('Recordatorios', style: AppText.h1),
              ),
              const SizedBox(height: 16),
              _TimeCard(
                settings: s,
                onEdit: () => _editTime(context, controller),
                onToggleDay: controller.toggleDay,
              ),
              const SizedBox(height: 16),
              _TogglesCard(settings: s, controller: controller),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.schedule_rounded,
                child: Text.rich(
                  TextSpan(
                    style: AppText.caption.copyWith(
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                    children: next == null
                        ? [const TextSpan(text: _noAlertsMessage)]
                        : [
                            const TextSpan(text: 'Próximo aviso: '),
                            TextSpan(
                              text:
                                  '${EsDates.shortDay(next)}, '
                                  '${EsDates.time12(next.hour, next.minute)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _InfoRow(
                icon: Icons.info_outline_rounded,
                child: Text(
                  'Los avisos aparecen mientras FastFashion está abierta. '
                  'Instálala en tu pantalla de inicio para tenerla a mano '
                  'cada mañana.',
                  style: AppText.caption,
                ),
              ),
              if (controller.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  controller.error!,
                  style: AppText.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _noAlertsMessage =
    'No tienes avisos programados. Activa «Outfit del día» y elige al '
    'menos un día.';

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.settings,
    required this.onEdit,
    required this.onToggleDay,
  });

  final ReminderSettings settings;
  final VoidCallback onEdit;
  final ValueChanged<int> onToggleDay;

  @override
  Widget build(BuildContext context) {
    final h = settings.hour % 12 == 0 ? 12 : settings.hour % 12;
    final mm = settings.minute.toString().padLeft(2, '0');
    final suffix = settings.hour < 12 ? 'a.m.' : 'p.m.';
    final compact = context.isCompact;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TU OUTFIT LLEGA A LAS',
            style: AppText.overline.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Hora del aviso: $h:$mm $suffix',
                  excludeSemantics: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$h:$mm',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 56,
                            height: 1,
                            letterSpacing: -1.7,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          suffix,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'Editar hora',
                excludeSemantics: true,
                child: Material(
                  color: AppColors.white.withValues(alpha: 0.2),
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onEdit,
                    child: const SizedBox(
                      height: 44,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Text(
                            'Editar',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _DayButton(
                    label: ReminderSettings.weekdayLabels[i],
                    fullName: ReminderSettings.weekdayNames[i],
                    on: settings.days[i],
                    onTap: () => onToggleDay(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.label,
    required this.fullName,
    required this.on,
    required this.onTap,
  });

  final String label;
  final String fullName;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: fullName,
      excludeSemantics: true,
      child: Material(
        color: on ? AppColors.white : AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: on ? AppColors.primary : AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TogglesCard extends StatelessWidget {
  const _TogglesCard({required this.settings, required this.controller});

  final ReminderSettings settings;
  final RemindersController controller;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool, ValueChanged<bool>)>[
      (
        'Outfit del día',
        'Un aviso a la hora elegida con tu combinación lista.',
        settings.dailyOutfit,
        controller.setDailyOutfit,
      ),
      (
        'Cambio de clima',
        'Te avisamos si el pronóstico cambia y tu outfit ya no sirve.',
        settings.weatherChange,
        controller.setWeatherChange,
      ),
      (
        'Avisos inteligentes',
        'Detectamos cuándo te toca cambiarte, como antes del gimnasio.',
        settings.smartAlerts,
        controller.setSmartAlerts,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 2, thickness: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].$1,
                          style: AppText.label.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(rows[i].$2, style: AppText.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FfSwitch(
                    value: rows[i].$3,
                    semanticLabel: rows[i].$1,
                    onChanged: rows[i].$4,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
