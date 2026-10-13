import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/format/dates.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/occasion.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/smart_alerts.dart';
import '../../domain/services/outfit_engine.dart';
import '../auth/auth_controller.dart';
import '../closet/closet_controller.dart';
import 'weather_controller.dart';

enum TodayStatus {
  /// Esperando clóset o sesión.
  loading,

  /// Falta al menos una camisa o un pantalón.
  needsGarments,

  /// Hay una propuesta lista.
  ready,
}

/// ViewModel de la pantalla Hoy: genera, cicla y guarda el outfit del día.
class TodayController extends ChangeNotifier {
  TodayController({
    required this._closet,
    required this._weather,
    required this._outfits,
    required this._garments,
    required this._auth,
    this._engine = const OutfitEngine(),
    this._clock = DateTime.now,
  }) {
    _userId = _auth.user?.id;
    _closet.addListener(_onDependencyChanged);
    _weather.addListener(_onDependencyChanged);
    _auth.addListener(_onAuthChanged);
    if (_userId != null) _restoreToday();
  }

  final ClosetController _closet;
  final WeatherController _weather;
  final OutfitRepository _outfits;
  final GarmentRepository _garments;
  final AuthController _auth;
  final OutfitEngine _engine;
  final DateTime Function() _clock;

  String? _userId;
  Occasion _occasion = Occasion.classes;
  List<OutfitProposal> _proposals = const [];
  int _index = 0;
  int _seed = 0;
  Duration _elapsed = Duration.zero;
  OutfitRecord? _record;
  bool _saving = false;
  bool _restoring = false;
  String? _error;
  String? _lastWeatherKey;
  final Set<AlertKind> _dismissedAlerts = {};

  Occasion get occasion => _occasion;
  OutfitProposal? get current => _proposals.isEmpty ? null : _proposals[_index];
  int get optionIndex => _index;
  int get optionCount => _proposals.length;
  Duration get generatedIn => _elapsed;
  bool get saving => _saving;

  /// Avisos que el usuario cerró en esta sesión.
  Set<AlertKind> get dismissedAlerts => Set.unmodifiable(_dismissedAlerts);
  String? get error => _error;

  /// ¿El outfit mostrado es el que el usuario ya eligió para hoy?
  bool get usedToday {
    final record = _record;
    final proposal = current;
    if (record == null || proposal == null) return false;
    final a = record.garmentIds.toSet();
    final b = proposal.garments.map((g) => g.id).toSet();
    return a.length == b.length && a.containsAll(b);
  }

  TodayStatus get status {
    if (_userId == null || !_closet.loaded || _restoring) {
      return TodayStatus.loading;
    }
    return current == null ? TodayStatus.needsGarments : TodayStatus.ready;
  }

  // ---- Acciones -------------------------------------------------------------

  void dismissAlert(AlertKind kind) {
    _dismissedAlerts.add(kind);
    notifyListeners();
  }

  void setOccasion(Occasion value) {
    if (_occasion == value) return;
    _occasion = value;
    _seed = 0;
    _regenerate(keepUsed: false);
  }

  /// "Otra opción": avanza por las alternativas y, al agotarlas, genera más.
  void next() {
    if (_proposals.isEmpty) return;
    if (_index + 1 < _proposals.length) {
      _index++;
      notifyListeners();
    } else {
      _seed++;
      _regenerate(keepUsed: true, exclude: current?.signature);
    }
  }

  /// Guarda el outfit mostrado como el de hoy y suma un uso a cada prenda.
  Future<bool> useCurrent() async {
    final proposal = current;
    if (proposal == null) return false;
    return adopt(proposal);
  }

  /// Fija [proposal] como el outfit de hoy (lo usa también el asistente).
  Future<bool> adopt(OutfitProposal proposal) async {
    final userId = _userId;
    if (userId == null || _saving) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final now = _clock();
      final alreadyToday = _record != null && _sameGarments(_record!, proposal);
      _record = await _outfits.saveForDate(
        userId: userId,
        date: EsDates.dayKey(now),
        proposal: proposal,
      );
      if (!alreadyToday) {
        await _garments.markWorn(
          userId,
          proposal.garments.map((g) => g.id).toList(),
          now,
        );
        await _closet.refresh();
      }
      // Mostramos el outfit adoptado como el actual, aunque venga del asistente.
      final others = _proposals.where((p) => p.signature != proposal.signature);
      _proposals = [_refreshed(proposal), ...others];
      _index = 0;
      return true;
    } on AppFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // ---- Internos -------------------------------------------------------------

  bool _sameGarments(OutfitRecord record, OutfitProposal proposal) {
    final a = record.garmentIds.toSet();
    final b = proposal.garments.map((g) => g.id).toSet();
    return a.length == b.length && a.containsAll(b);
  }

  /// Re-resuelve las prendas de [p] con los datos más recientes del clóset.
  OutfitProposal _refreshed(OutfitProposal p) {
    Garment? fresh(Garment? g) => g == null ? null : (_closet.byId(g.id) ?? g);
    return OutfitProposal(
      top: fresh(p.top)!,
      bottom: fresh(p.bottom)!,
      shoes: fresh(p.shoes),
      jacket: fresh(p.jacket),
      title: p.title,
      occasion: p.occasion,
      style: p.style,
      score: p.score,
      reasons: p.reasons,
    );
  }

  Future<void> _restoreToday() async {
    final userId = _userId;
    if (userId == null) return;
    _restoring = true;
    notifyListeners();
    try {
      _record = await _outfits.forDate(userId, EsDates.dayKey(_clock()));
    } on AppFailure {
      _record = null;
    } finally {
      _restoring = false;
    }
    _regenerate(keepUsed: true);
  }

  OutfitProposal? _proposalFromRecord(OutfitRecord record) {
    Garment? find(String? id) => id == null ? null : _closet.byId(id);
    final top = find(record.topId);
    final bottom = find(record.bottomId);
    if (top == null || bottom == null) return null;
    return OutfitProposal(
      top: top,
      bottom: bottom,
      shoes: find(record.shoesId),
      jacket: find(record.jacketId),
      title: record.title,
      occasion: record.occasion,
      style: record.style,
      reasons: const ['Lo elegiste tú para hoy'],
    );
  }

  void _regenerate({required bool keepUsed, String? exclude}) {
    if (!_closet.loaded) {
      notifyListeners();
      return;
    }
    final watch = Stopwatch()..start();
    final proposals = _engine.suggest(
      _closet.garments,
      OutfitRequest(
        now: _clock(),
        occasion: _occasion,
        weather: _weather.snapshot,
        seed: _seed,
        exclude: {?exclude},
      ),
    );
    watch.stop();
    _elapsed = watch.elapsed;

    final record = _record;
    final used = (keepUsed && record != null)
        ? _proposalFromRecord(record)
        : null;
    if (used != null) {
      _proposals = [
        used,
        ...proposals.where((p) => p.signature != used.signature),
      ];
    } else {
      _proposals = proposals;
    }
    _index = 0;
    _lastWeatherKey = _weatherKey();
    notifyListeners();
  }

  String _weatherKey() {
    final w = _weather.snapshot;
    return w == null
        ? 'none'
        : '${w.temperatureC.round()}-${w.rainProbability}-${w.isFallback}';
  }

  void _onDependencyChanged() {
    if (_userId == null || !_closet.loaded || _restoring || _saving) return;

    final weatherChanged = _weatherKey() != _lastWeatherKey;
    final cur = current;
    final stale =
        cur != null && cur.garments.any((g) => _closet.byId(g.id) == null);
    final needsFirst = cur == null && _closet.garments.isNotEmpty;

    if (weatherChanged || stale || needsFirst) {
      _regenerate(keepUsed: true);
    } else {
      notifyListeners(); // p. ej. cambió un nombre o contador
    }
  }

  void _onAuthChanged() {
    final next = _auth.user?.id;
    if (next == _userId) return;
    _userId = next;
    _proposals = const [];
    _index = 0;
    _record = null;
    _seed = 0;
    _dismissedAlerts.clear();
    notifyListeners();
    if (next != null) _restoreToday();
  }

  @override
  void dispose() {
    _closet.removeListener(_onDependencyChanged);
    _weather.removeListener(_onDependencyChanged);
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
