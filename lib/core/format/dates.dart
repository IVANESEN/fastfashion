/// Formatos de fecha y hora en español, sin depender de datos de `intl`
/// (evita inicializar locales y funciona igual en web, pruebas y móvil).
abstract final class EsDates {
  static const _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String weekday(DateTime d) => _weekdays[d.weekday - 1];
  static String month(DateTime d) => _months[d.month - 1];

  static String _cap(String s) => s[0].toUpperCase() + s.substring(1);

  /// "Viernes 9 de octubre"
  static String longDay(DateTime d) =>
      '${_cap(weekday(d))} ${d.day} de ${month(d)}';

  /// "lunes 12 oct"
  static String shortDay(DateTime d) =>
      '${weekday(d)} ${d.day} ${month(d).substring(0, 3)}';

  /// "6:30 a.m."
  static String time12(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$h:$mm ${hour < 12 ? 'a.m.' : 'p.m.'}';
  }

  /// `yyyy-MM-dd`, la clave de día de los outfits.
  static String dayKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  /// "hoy", "ayer", "hace 3 días", "hace 2 semanas"…
  static String relative(DateTime when, DateTime now) {
    final a = DateTime(when.year, when.month, when.day);
    final b = DateTime(now.year, now.month, now.day);
    final days = b.difference(a).inDays;
    if (days <= 0) return 'hoy';
    if (days == 1) return 'ayer';
    if (days < 7) return 'hace $days días';
    if (days < 30) {
      final w = days ~/ 7;
      return w == 1 ? 'hace 1 semana' : 'hace $w semanas';
    }
    final m = days ~/ 30;
    return m == 1 ? 'hace 1 mes' : 'hace $m meses';
  }
}
