/// Preferencias de avisos del usuario. Una fila por usuario.
class ReminderSettings {
  const ReminderSettings({
    required this.userId,
    this.hour = 6,
    this.minute = 30,
    this.days = const [true, true, true, true, true, false, false],
    this.dailyOutfit = true,
    this.weatherChange = true,
    this.smartAlerts = false,
  });

  final String userId;
  final int hour;
  final int minute;

  /// Lunes (0) a domingo (6).
  final List<bool> days;

  /// "Outfit del día": notificación a la hora elegida.
  final bool dailyOutfit;

  /// "Cambio de clima": avisa si el pronóstico invalida el outfit.
  final bool weatherChange;

  /// "Avisos inteligentes": detecta cuándo toca cambiarse.
  final bool smartAlerts;

  static const weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const weekdayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  bool get hasAnyDay => days.any((d) => d);

  /// Próximo disparo del aviso diario a partir de [from], o `null` si el aviso
  /// está apagado o no hay días activos.
  DateTime? nextFire(DateTime from) {
    if (!dailyOutfit || !hasAnyDay) return null;
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(from.year, from.month, from.day).add(Duration(days: offset));
      final candidate = DateTime(day.year, day.month, day.day, hour, minute);
      // DateTime.weekday: lunes = 1 … domingo = 7
      if (days[candidate.weekday - 1] && candidate.isAfter(from)) return candidate;
    }
    return null;
  }

  ReminderSettings copyWith({
    int? hour,
    int? minute,
    List<bool>? days,
    bool? dailyOutfit,
    bool? weatherChange,
    bool? smartAlerts,
  }) {
    return ReminderSettings(
      userId: userId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      dailyOutfit: dailyOutfit ?? this.dailyOutfit,
      weatherChange: weatherChange ?? this.weatherChange,
      smartAlerts: smartAlerts ?? this.smartAlerts,
    );
  }

  Map<String, dynamic> toRow() => {
        'user_id': userId,
        'hour': hour,
        'minute': minute,
        'days': days,
        'daily_outfit': dailyOutfit,
        'weather_change': weatherChange,
        'smart_alerts': smartAlerts,
      };

  factory ReminderSettings.fromRow(Map<String, dynamic> row) {
    final rawDays = row['days'];
    final days = rawDays is List && rawDays.length == 7
        ? rawDays.map((e) => e == true).toList()
        : const [true, true, true, true, true, false, false];
    return ReminderSettings(
      userId: row['user_id'] as String,
      hour: (row['hour'] as num?)?.toInt() ?? 6,
      minute: (row['minute'] as num?)?.toInt() ?? 30,
      days: days,
      dailyOutfit: row['daily_outfit'] as bool? ?? true,
      weatherChange: row['weather_change'] as bool? ?? true,
      smartAlerts: row['smart_alerts'] as bool? ?? false,
    );
  }
}
