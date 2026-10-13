import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/format/dates.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/repositories.dart';
import '../auth/auth_controller.dart';

/// Preferencias de avisos con guardado inmediato (optimista).
class RemindersController extends ChangeNotifier {
  RemindersController({
    required ReminderRepository repository,
    required this._auth,
    this._clock = DateTime.now,
  }) : _repo = repository {
    _userId = _auth.user?.id;
    _auth.addListener(_onAuthChanged);
    if (_userId != null) load();
  }

  /// Si la app se abre pasada la hora, aún avisamos durante esta ventana.
  static const lateWindow = Duration(hours: 3);

  final ReminderRepository _repo;
  final AuthController _auth;
  final DateTime Function() _clock;

  String? _userId;
  ReminderSettings? _settings;
  bool _loading = false;
  String? _error;
  String? _lastFiredDay;

  /// Preferencias actuales, o las de fábrica mientras cargan.
  ReminderSettings get settings =>
      _settings ?? ReminderSettings(userId: _userId ?? '');
  bool get loading => _loading;
  String? get error => _error;

  /// Próximo aviso diario, o `null` si está apagado o sin días.
  DateTime? get nextFire => settings.nextFire(_clock());

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _settings = await _repo.load(userId);
    } on AppFailure catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setTime(int hour, int minute) =>
      _update(settings.copyWith(hour: hour, minute: minute));

  Future<void> toggleDay(int index) {
    final days = [...settings.days];
    days[index] = !days[index];
    return _update(settings.copyWith(days: days));
  }

  Future<void> setDailyOutfit(bool value) =>
      _update(settings.copyWith(dailyOutfit: value));

  Future<void> setWeatherChange(bool value) =>
      _update(settings.copyWith(weatherChange: value));

  Future<void> setSmartAlerts(bool value) =>
      _update(settings.copyWith(smartAlerts: value));

  Future<void> _update(ReminderSettings next) async {
    if (_userId == null) return;
    final previous = _settings;
    _settings = next; // optimista: la UI responde al instante
    _error = null;
    notifyListeners();
    try {
      _settings = await _repo.save(next);
    } on AppFailure catch (e) {
      _settings = previous;
      _error = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// ¿Toca avisar ahora? Devuelve `true` **una sola vez por día**.
  ///
  /// Cubre la hora exacta y también abrir la app hasta [lateWindow] después.
  bool takeDue([DateTime? at]) {
    final now = at ?? _clock();
    final s = settings;
    if (!s.dailyOutfit || !s.days[now.weekday - 1]) return false;
    final key = EsDates.dayKey(now);
    if (_lastFiredDay == key) return false;
    final scheduled = DateTime(now.year, now.month, now.day, s.hour, s.minute);
    final due =
        !now.isBefore(scheduled) && now.difference(scheduled) <= lateWindow;
    if (!due) return false;
    _lastFiredDay = key;
    return true;
  }

  void _onAuthChanged() {
    final next = _auth.user?.id;
    if (next == _userId) return;
    _userId = next;
    _settings = null;
    _lastFiredDay = null;
    notifyListeners();
    if (next != null) load();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
