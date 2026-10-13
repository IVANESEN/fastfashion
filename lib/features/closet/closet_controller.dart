import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/garment_category.dart';
import '../../domain/entities/garment_color.dart';
import '../../domain/entities/garment_style.dart';
import '../../domain/repositories/repositories.dart';
import '../auth/auth_controller.dart';

/// Estado del clóset del usuario con búsqueda y filtros combinables.
///
/// Se reinicia solo cuando cambia la sesión (otro usuario, cierre de sesión).
class ClosetController extends ChangeNotifier {
  ClosetController({
    required GarmentRepository repository,
    required AuthController auth,
  }) : _repo = repository,
       _auth = auth {
    _userId = auth.user?.id;
    _auth.addListener(_onAuthChanged);
    if (_userId != null) load();
  }

  final GarmentRepository _repo;
  final AuthController _auth;

  String? _userId;
  List<Garment> _all = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  GarmentCategory? _category;
  GarmentStyle? _style;
  String? _colorName;
  String _query = '';

  List<Garment> get garments => _all;
  bool get loading => _loading;

  /// `true` tras la primera carga (distingue "cargando" de "vacío").
  bool get loaded => _loaded;
  String? get error => _error;

  GarmentCategory? get category => _category;
  GarmentStyle? get style => _style;
  String? get colorName => _colorName;
  String get query => _query;

  bool get hasFilters =>
      _category != null ||
      _style != null ||
      _colorName != null ||
      _query.trim().isNotEmpty;

  /// Colores presentes en el clóset, del más al menos frecuente.
  List<GarmentColor> get availableColors {
    final counts = <String, int>{};
    final byName = <String, GarmentColor>{};
    for (final g in _all) {
      counts.update(g.color.name, (n) => n + 1, ifAbsent: () => 1);
      byName[g.color.name] = g.color;
    }
    final names = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return names.map((n) => byName[n]!).toList();
  }

  List<Garment> get filtered {
    final q = _normalize(_query.trim());
    return _all.where((g) {
      if (_category != null && g.category != _category) return false;
      if (_style != null && g.style != _style) return false;
      if (_colorName != null && g.color.name != _colorName) return false;
      if (q.isEmpty) return true;
      final haystack = _normalize(
        '${g.name} ${g.category.label} ${g.category.plural} '
        '${g.style.label} ${g.color.name}',
      );
      return q.split(' ').every(haystack.contains);
    }).toList();
  }

  Garment? byId(String id) {
    for (final g in _all) {
      if (g.id == id) return g;
    }
    return null;
  }

  // ---- Filtros --------------------------------------------------------------

  void setCategory(GarmentCategory? value) {
    _category = value;
    notifyListeners();
  }

  void setStyle(GarmentStyle? value) {
    _style = value;
    notifyListeners();
  }

  /// Vuelve a pulsar el mismo color para quitar el filtro.
  void toggleColor(String name) {
    _colorName = _colorName == name ? null : name;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void clearFilters() {
    _category = null;
    _style = null;
    _colorName = null;
    _query = '';
    notifyListeners();
  }

  // ---- Datos ----------------------------------------------------------------

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.list(userId);
      _loaded = true;
    } on AppFailure catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Garment?> add({
    required String name,
    required GarmentCategory category,
    required GarmentStyle style,
    required GarmentColor color,
    Uint8List? imageBytes,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    return _guard(() async {
      final created = await _repo.create(
        userId: userId,
        name: name,
        category: category,
        style: style,
        color: color,
        imageBytes: imageBytes,
      );
      _all = [created, ..._all];
      notifyListeners();
      return created;
    });
  }

  Future<Garment?> update(Garment garment, {Uint8List? imageBytes}) {
    return _guard(() async {
      final saved = await _repo.update(garment, imageBytes: imageBytes);
      _all = [for (final g in _all) g.id == saved.id ? saved : g];
      notifyListeners();
      return saved;
    });
  }

  Future<bool> delete(Garment garment) async {
    final ok = await _guard(() async {
      await _repo.delete(garment);
      _all = _all.where((g) => g.id != garment.id).toList();
      notifyListeners();
      return true;
    });
    return ok ?? false;
  }

  /// Agrega el clóset de ejemplo. Devuelve cuántas prendas creó.
  Future<int> addSamples() async {
    final userId = _userId;
    if (userId == null) return 0;
    final count = await _guard(() async {
      final n = await _repo.addSamples(userId);
      await load();
      return n;
    });
    return count ?? 0;
  }

  /// Recarga después de que otra parte de la app cambió contadores de uso.
  Future<void> refresh() => load();

  Future<T?> _guard<T>(Future<T> Function() action) async {
    _error = null;
    try {
      return await action();
    } on AppFailure catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _onAuthChanged() {
    final next = _auth.user?.id;
    if (next == _userId) return;
    _userId = next;
    _all = const [];
    _loaded = false;
    clearFilters();
    if (next != null) load();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  static String _normalize(String s) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final b = StringBuffer();
    for (final rune in s.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString();
  }
}
