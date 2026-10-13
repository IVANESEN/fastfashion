import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/format/dates.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/ff_chip.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../core/widgets/horizontal_scroller.dart';
import '../../domain/entities/occasion.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../auth/auth_controller.dart';
import '../../domain/services/smart_alerts.dart';
import '../closet/closet_controller.dart';
import '../reminders/reminders_controller.dart';
import 'outfit_board.dart';
import 'today_controller.dart';
import 'weather_controller.dart';

/// 02 · Hoy: clima, ocasión y el outfit del día.
class TodayScreen extends StatelessWidget {
  const TodayScreen({this.clock = DateTime.now, super.key});

  /// Inyectable para que el encabezado sea determinista en pruebas.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final today = context.watch<TodayController>();
    final weather = context.watch<WeatherController>();
    final closet = context.watch<ClosetController>();
    final reminders = context.watch<RemindersController>();
    final pad = context.pagePadding;
    final user = auth.user;

    final children = <Widget>[
      const SizedBox(height: 12),
      _Header(
        dateLabel: EsDates.longDay(clock()).toUpperCase(),
        name: user?.firstName ?? '',
        initial: user?.initial ?? '?',
        onProfile: () => context.push(AppRoutes.profile),
      ),
      const SizedBox(height: 16),
      _WeatherCard(weather: weather),
      const SizedBox(height: 14),
      _OccasionChips(
        selected: today.occasion,
        onSelect: today.setOccasion,
        pad: pad,
      ),
      const SizedBox(height: 16),
    ];

    switch (today.status) {
      case TodayStatus.loading:
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      case TodayStatus.needsGarments:
        children.add(
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 280),
            child: EmptyState(
              icon: Icons.checkroom_outlined,
              title: closet.garments.isEmpty
                  ? 'Aún no tienes prendas'
                  : 'Faltan prendas para combinar',
              message:
                  'Para armar un outfit necesitamos al menos una camisa y '
                  'un pantalón en tu clóset.',
              actionLabel: 'Agregar prenda',
              onAction: () => context.push(AppRoutes.addGarment),
              secondaryLabel: closet.garments.isEmpty
                  ? 'Cargar prendas de ejemplo'
                  : null,
              onSecondary: closet.garments.isEmpty
                  ? () => closet.addSamples()
                  : null,
            ),
          ),
        );
      case TodayStatus.ready:
        final alerts = SmartAlerts.evaluate(
          now: clock(),
          settings: reminders.settings,
          weather: weather.snapshot,
          chosen: today.usedToday ? today.current : null,
          closet: closet.garments,
          dismissed: today.dismissedAlerts,
        );
        for (final alert in alerts) {
          children
            ..add(
              _AlertBanner(
                alert: alert,
                onAction: () {
                  today.dismissAlert(alert.kind);
                  if (alert.kind == AlertKind.smart) {
                    today.setOccasion(Occasion.sport);
                  } else {
                    today.next();
                  }
                },
                onDismiss: () => today.dismissAlert(alert.kind),
              ),
            )
            ..add(const SizedBox(height: 12));
        }
        children.add(_OutfitSection(today: today));
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await weather.refresh();
          await closet.load();
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final w in children)
                  w is _OccasionChips
                      ? w
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: pad),
                          child: w,
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.dateLabel,
    required this.name,
    required this.initial,
    required this.onProfile,
  });

  final String dateLabel;
  final String name;
  final String initial;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.overline.copyWith(letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Semantics(
                header: true,
                child: Text(
                  name.isEmpty ? 'Hola' : 'Hola, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InitialAvatar(initial: initial, onTap: onProfile),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});

  final WeatherController weather;

  IconData _icon(WeatherSnapshot w) {
    if (w.isRainLikely) return Icons.umbrella_outlined;
    if (w.isHot) return Icons.wb_sunny_outlined;
    if (w.isCold) return Icons.ac_unit_rounded;
    return Icons.wb_cloudy_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final w = weather.snapshot;
    final String title;
    final String body;
    final IconData icon;
    if (w == null) {
      title = weather.city.name;
      body = 'Consultando el clima…';
      icon = Icons.cloud_queue_rounded;
    } else {
      title = '${w.cityName} · ${w.temperatureC.round()}°C';
      body = w.isFallback
          ? 'Sin conexión: usamos un clima típico de la ciudad'
          : w.advice;
      icon = _icon(w);
    }

    return Semantics(
      container: true,
      label: 'Clima. $title. $body',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title),
                  const SizedBox(height: 2),
                  Text(body, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccasionChips extends StatelessWidget {
  const _OccasionChips({
    required this.selected,
    required this.onSelect,
    required this.pad,
  });

  final Occasion selected;
  final ValueChanged<Occasion> onSelect;
  final double pad;

  @override
  Widget build(BuildContext context) {
    return HorizontalScroller(
      padding: EdgeInsets.symmetric(horizontal: pad),
      children: [
        for (final o in Occasion.values)
          FfChip(
            label: o.label,
            selected: selected == o,
            onTap: () => onSelect(o),
          ),
      ],
    );
  }
}

class _OutfitSection extends StatelessWidget {
  const _OutfitSection({required this.today});

  final TodayController today;

  @override
  Widget build(BuildContext context) {
    final outfit = today.current!;
    final used = today.usedToday;
    final seconds = today.generatedIn.inMicroseconds / 1e6;
    final timeLabel = seconds < 0.01
        ? 'Generado en menos de 0.01 s'
        : 'Generado en ${seconds.toStringAsFixed(2)} s';

    final primary = FfButton(
      label: used ? 'Outfit de hoy guardado' : 'Usar este outfit',
      style: FfButtonStyle.ink,
      icon: used ? Icons.check_rounded : null,
      loading: today.saving,
      onPressed: used ? null : () => _use(context),
    );
    final another = FfButton(
      label: 'Otra opción',
      style: FfButtonStyle.outline,
      icon: Icons.refresh_rounded,
      expand: false,
      onPressed: today.next,
    );

    // En pantallas angostas o con texto grande los controles se apilan.
    final stacked =
        context.screenWidth < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final optionLabel =
        'Opción ${today.optionIndex + 1} de ${today.optionCount}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          used ? 'TU OUTFIT DE HOY' : 'TU OUTFIT SUGERIDO',
                          style: AppText.overline.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Semantics(
                          header: true,
                          child: Text(
                            outfit.title,
                            style: AppText.h2.copyWith(color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!stacked) ...[
                    const SizedBox(width: 8),
                    FfTag(optionLabel),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              OutfitBoard(proposal: outfit),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (stacked) FfTag(optionLabel),
                  FfTag(outfit.occasion.label),
                  FfTag(outfit.style.label),
                  FfTag(timeLabel),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (stacked) ...[
          primary,
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: another),
        ] else
          Row(
            children: [
              Expanded(child: primary),
              const SizedBox(width: 10),
              another,
            ],
          ),
        if (outfit.reasons.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Por qué este outfit', style: AppText.title),
          const SizedBox(height: 8),
          for (final r in outfit.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3, right: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(child: Text(r, style: AppText.body)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _use(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await today.useCurrent();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '¡Listo! Este es tu outfit de hoy.'
              : (today.error ?? 'No pudimos guardar el outfit.'),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.alert,
    required this.onAction,
    required this.onDismiss,
  });

  final OutfitAlert alert;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(alert.message, style: AppText.body)),
                FfIconButton(
                  icon: Icons.close_rounded,
                  label: 'Cerrar aviso',
                  background: Colors.transparent,
                  onPressed: onDismiss,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 12),
                child: FfButton(
                  label: alert.actionLabel,
                  style: FfButtonStyle.tonal,
                  expand: false,
                  height: 44,
                  onPressed: onAction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
