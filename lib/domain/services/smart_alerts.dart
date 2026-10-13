import '../entities/garment.dart';
import '../entities/garment_category.dart';
import '../entities/garment_style.dart';
import '../entities/outfit.dart';
import '../entities/reminder_settings.dart';
import '../entities/weather_snapshot.dart';

enum AlertKind {
  /// Cambió el clima y el outfit elegido ya no es lo ideal.
  weather,

  /// Tarde del día: sugerimos cambiarse a algo deportivo.
  smart,
}

class OutfitAlert {
  const OutfitAlert({
    required this.kind,
    required this.message,
    required this.actionLabel,
  });

  final AlertKind kind;
  final String message;
  final String actionLabel;
}

/// Reglas puras de los avisos "Cambio de clima" y "Avisos inteligentes".
///
/// Se evalúan al mostrar la pantalla Hoy, solo para el outfit que el usuario
/// ya eligió, y respetan los interruptores de Recordatorios.
abstract final class SmartAlerts {
  static List<OutfitAlert> evaluate({
    required DateTime now,
    required ReminderSettings settings,
    required WeatherSnapshot? weather,
    required OutfitProposal? chosen,
    required List<Garment> closet,
    Set<AlertKind> dismissed = const {},
  }) {
    if (chosen == null) return const [];
    final alerts = <OutfitAlert>[];

    if (settings.weatherChange &&
        !dismissed.contains(AlertKind.weather) &&
        weather != null &&
        weather.isRainLikely) {
      final shoes = chosen.shoes;
      final fragile =
          shoes != null &&
          (shoes.style != GarmentStyle.sporty ||
              shoes.name.toLowerCase().contains('sandalia'));
      if (fragile) {
        final at = weather.rainExpectedAt;
        final when = at == null ? '' : ' a las ${_hour12(at)}';
        alerts.add(
          OutfitAlert(
            kind: AlertKind.weather,
            message:
                'Va a llover$when y llevas ${shoes.name.toLowerCase()}. '
                'Hay opciones mejores para la lluvia.',
            actionLabel: 'Ver otra opción',
          ),
        );
      }
    }

    if (settings.smartAlerts &&
        !dismissed.contains(AlertKind.smart) &&
        now.hour >= 16 &&
        chosen.style != GarmentStyle.sporty) {
      bool sporty(GarmentCategory c) =>
          closet.any((g) => g.category == c && g.style == GarmentStyle.sporty);
      if (sporty(GarmentCategory.top) && sporty(GarmentCategory.bottom)) {
        alerts.add(
          const OutfitAlert(
            kind: AlertKind.smart,
            message:
                '¿Entrenas hoy? Armamos un look deportivo con lo que ya '
                'tienes.',
            actionLabel: 'Armar look deportivo',
          ),
        );
      }
    }
    return alerts;
  }

  static String _hour12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h ${t.hour < 12 ? 'a.m.' : 'p.m.'}';
  }
}
