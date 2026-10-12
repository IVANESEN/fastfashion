/// Clima actual y probabilidad de lluvia del resto del día.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.cityName,
    required this.temperatureC,
    required this.rainProbability,
    required this.fetchedAt,
    this.rainExpectedAt,
    this.isFallback = false,
  });

  final String cityName;
  final double temperatureC;

  /// Máxima probabilidad de precipitación (0–100) en lo que resta del día.
  final int rainProbability;

  /// Primera hora en la que se espera lluvia (≥ 50 %), si la hay.
  final DateTime? rainExpectedAt;
  final DateTime fetchedAt;

  /// `true` cuando no hubo red y se usó un valor típico de la ciudad.
  final bool isFallback;

  bool get isRainLikely => rainProbability >= 50;
  bool get isHot => temperatureC >= 27;
  bool get isCold => temperatureC <= 17;
  bool get isMild => !isHot && !isCold;

  /// Frase corta para la tarjeta de clima.
  String get advice {
    if (isRainLikely) {
      final at = rainExpectedAt;
      final when = at == null ? '' : ' a las ${_hour12(at)}';
      return 'Lluvia probable$when — evitamos prendas que se arruinan con agua';
    }
    if (isHot) return 'Día caluroso — elegimos prendas ligeras';
    if (isCold) return 'Hace frío — sumamos una capa extra';
    return 'Clima templado — cualquier combinación funciona';
  }

  static String _hour12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h ${t.hour < 12 ? 'a.m.' : 'p.m.'}';
  }
}
