import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../datasource/database_client.dart';
import 'key_value_store.dart';

/// Base de datos genérica embebida: tablas de filas JSON persistidas en un
/// [KeyValueStore]. Implementa el mismo contrato que Supabase, por lo que
/// migrar es cambiar `BACKEND=supabase` sin tocar repositorios ni UI.
class LocalDatabase implements DatabaseClient, FileStorage {
  LocalDatabase(this._store, {this._uuid = const Uuid()});

  static const _prefix = 'ff.db.';

  final KeyValueStore _store;
  final Uuid _uuid;
  final Map<String, List<Row>> _tables = {};

  List<Row> _table(String name) {
    return _tables.putIfAbsent(name, () {
      final raw = _store.read('$_prefix$name');
      if (raw == null || raw.isEmpty) return <Row>[];
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList();
      } on FormatException {
        return <Row>[];
      }
    });
  }

  Future<void> _persist(String name) async {
    final ok = await _store.write('$_prefix$name', jsonEncode(_table(name)));
    if (!ok) {
      throw const UnknownFailure(
        'El almacenamiento del navegador está lleno. '
        'Elimina algunas prendas con foto e intenta de nuevo.',
      );
    }
  }

  static bool _matches(Row row, Map<String, Object?> where) {
    for (final entry in where.entries) {
      if (row[entry.key] != entry.value) return false;
    }
    return true;
  }

  static int _compare(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1; // nulos al final
    if (b == null) return -1;
    if (a is num && b is num) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }

  @override
  Future<List<Row>> select(
    String table, {
    Map<String, Object?> where = const {},
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    var rows = _table(table).where((r) => _matches(r, where)).toList();
    if (orderBy != null) {
      rows.sort((a, b) {
        final c = _compare(a[orderBy], b[orderBy]);
        return descending ? -c : c;
      });
    }
    if (limit != null && rows.length > limit) rows = rows.sublist(0, limit);
    return rows.map(Row.from).toList();
  }

  @override
  Future<Row?> selectOne(
    String table, {
    required Map<String, Object?> where,
  }) async {
    final rows = await select(table, where: where, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<Row> insert(String table, Row row) async {
    final copy = Row.from(row);
    copy.putIfAbsent('id', () => _uuid.v4());
    _table(table).add(copy);
    await _persist(table);
    return Row.from(copy);
  }

  @override
  Future<List<Row>> insertMany(String table, List<Row> rows) async {
    final copies = rows.map((r) {
      final c = Row.from(r);
      c.putIfAbsent('id', () => _uuid.v4());
      return c;
    }).toList();
    _table(table).addAll(copies);
    await _persist(table);
    return copies.map(Row.from).toList();
  }

  @override
  Future<Row> upsert(
    String table,
    Row row, {
    required List<String> onConflict,
  }) async {
    final where = {for (final c in onConflict) c: row[c]};
    for (final existing in _table(table)) {
      if (_matches(existing, where)) {
        existing.addAll(row);
        await _persist(table);
        return Row.from(existing);
      }
    }
    return insert(table, row);
  }

  @override
  Future<Row?> update(
    String table, {
    required Map<String, Object?> where,
    required Row values,
  }) async {
    Row? first;
    for (final row in _table(table)) {
      if (_matches(row, where)) {
        row.addAll(values);
        first ??= Row.from(row);
      }
    }
    if (first != null) await _persist(table);
    return first;
  }

  @override
  Future<void> delete(
    String table, {
    required Map<String, Object?> where,
  }) async {
    final rows = _table(table);
    final before = rows.length;
    rows.removeWhere((r) => _matches(r, where));
    if (rows.length != before) await _persist(table);
  }

  /// Borra todas las tablas (útil para "restablecer" en demos y pruebas).
  Future<void> wipe(Iterable<String> tables) async {
    for (final t in tables) {
      _tables[t] = <Row>[];
      await _store.remove('$_prefix$t');
    }
  }

  // ---- FileStorage: en local la "URL" es un data-URI autocontenido ----

  @override
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    return 'data:$contentType;base64,${base64Encode(bytes)}';
  }

  @override
  Future<void> remove({required String bucket, required String path}) async {}
}
