import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/repositories/repositories.dart';
import '../auth/auth_controller.dart';

/// Clima de la ciudad del usuario, compartido por Hoy y el Asistente.
class WeatherController extends ChangeNotifier {
  WeatherController({
    required WeatherRepository repository,
    required AuthController auth,
  }) : _repo = repository,
       _auth = auth {
    _city = auth.user?.city;
    _auth.addListener(_onAuthChanged);
    if (_city != null) refresh();
  }

  final WeatherRepository _repo;
  final AuthController _auth;

  City? _city;
  WeatherSnapshot? _snapshot;
  bool _loading = false;
  bool _disposed = false;

  WeatherSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;
  City get city => _city ?? City.sanSalvador;

  Future<void> refresh() async {
    final target = _city;
    if (target == null || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _repo.current(target);
      // Si el usuario cambió de ciudad mientras esperábamos, descartamos.
      if (target.name == _city?.name) _snapshot = result;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _onAuthChanged() {
    final next = _auth.user?.city;
    if (next?.name == _city?.name) return;
    _city = next;
    _snapshot = null;
    notifyListeners();
    if (next != null) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
