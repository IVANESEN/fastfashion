import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/repositories/repositories.dart';

/// Clima real desde Open-Meteo (gratuito, sin API key, con CORS habilitado).
///
/// Si no hay red devuelve un valor típico marcado `isFallback` para que la
/// app siga siendo útil sin conexión.
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    http.Client? client,
    this._clock = DateTime.now,
    this.cacheFor = const Duration(minutes: 15),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final DateTime Function() _clock;
  final Duration cacheFor;
  final Map<String, WeatherSnapshot> _cache = {};

  @override
  Future<WeatherSnapshot> current(City city) async {
    final cached = _cache[city.name];
    if (cached != null &&
        !cached.isFallback &&
        _clock().difference(cached.fetchedAt) < cacheFor) {
      return cached;
    }
    try {
      final snapshot = await _fetch(city);
      _cache[city.name] = snapshot;
      return snapshot;
    } on Object {
      return cached ?? _fallback(city);
    }
  }

  Future<WeatherSnapshot> _fetch(City city) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': city.latitude.toStringAsFixed(4),
      'longitude': city.longitude.toStringAsFixed(4),
      'current': 'temperature_2m',
      'hourly': 'precipitation_probability',
      'timezone': 'auto',
      'forecast_days': '1',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) {
      throw StateError('Open-Meteo respondió ${res.statusCode}');
    }
    return parse(city, utf8.decode(res.bodyBytes), fetchedAt: _clock());
  }

  /// Interpreta la respuesta de Open-Meteo. Expuesto para pruebas.
  static WeatherSnapshot parse(
    City city,
    String body, {
    required DateTime fetchedAt,
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final temperature = (current['temperature_2m'] as num).toDouble();
    // Open-Meteo entrega la hora local de la ciudad sin zona (naive).
    final now = DateTime.parse(current['time'] as String);

    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List<dynamic>).cast<String>();
    final probs = (hourly['precipitation_probability'] as List<dynamic>)
        .map((e) => (e as num?)?.toInt() ?? 0)
        .toList();

    var maxProb = 0;
    DateTime? firstRain;
    for (var i = 0; i < times.length && i < probs.length; i++) {
      final t = DateTime.parse(times[i]);
      // Solo lo que resta del día (desde la hora actual).
      if (t.isBefore(DateTime(now.year, now.month, now.day, now.hour))) {
        continue;
      }
      if (probs[i] > maxProb) maxProb = probs[i];
      if (firstRain == null && probs[i] >= 50) firstRain = t;
    }

    return WeatherSnapshot(
      cityName: city.name,
      temperatureC: temperature,
      rainProbability: maxProb,
      rainExpectedAt: firstRain,
      fetchedAt: fetchedAt,
    );
  }

  WeatherSnapshot _fallback(City city) {
    return WeatherSnapshot(
      cityName: city.name,
      temperatureC: 26,
      rainProbability: 20,
      fetchedAt: _clock(),
      isFallback: true,
    );
  }
}
