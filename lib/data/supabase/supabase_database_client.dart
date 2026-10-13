import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../datasource/database_client.dart';

/// Traduce errores de Supabase a [AppFailure] con mensajes en español.
AppFailure mapSupabaseError(Object error) {
  if (error is AppFailure) return error;
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login')) {
      return const AuthFailure('Correo o contraseña incorrectos.');
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return const AuthFailure(
        'Ese correo ya tiene una cuenta. Inicia sesión.',
      );
    }
    if (msg.contains('email not confirmed')) {
      return const AuthFailure('Confirma tu correo antes de iniciar sesión.');
    }
    if (msg.contains('password')) {
      return const AuthFailure(
        'La contraseña no cumple los requisitos de seguridad.',
      );
    }
    return const AuthFailure('No pudimos validar tus datos. Intenta de nuevo.');
  }
  if (error is PostgrestException) {
    if (error.code == 'PGRST116') return const NotFoundFailure();
    return UnknownFailure('No se pudo completar la operación (${error.code}).');
  }
  if (error is StorageException) {
    return const UnknownFailure('No pudimos subir la foto. Intenta de nuevo.');
  }
  return const NetworkFailure();
}

/// [DatabaseClient] y [FileStorage] sobre un proyecto real de Supabase.
///
/// Las tablas y políticas RLS se crean con `supabase/schema.sql`.
class SupabaseDatabaseClient implements DatabaseClient, FileStorage {
  SupabaseDatabaseClient(this._client);

  final SupabaseClient _client;

  PostgrestFilterBuilder<T> _filter<T>(
    PostgrestFilterBuilder<T> query,
    Map<String, Object?> where,
  ) {
    var q = query;
    for (final entry in where.entries) {
      final value = entry.value;
      q = value == null ? q.isFilter(entry.key, null) : q.eq(entry.key, value);
    }
    return q;
  }

  @override
  Future<List<Row>> select(
    String table, {
    Map<String, Object?> where = const {},
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      PostgrestTransformBuilder<PostgrestList> query = _filter(
        _client.from(table).select(),
        where,
      );
      if (orderBy != null) {
        query = query.order(orderBy, ascending: !descending);
      }
      if (limit != null) query = query.limit(limit);
      final data = await query;
      return data.map(Row.from).toList();
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Row?> selectOne(
    String table, {
    required Map<String, Object?> where,
  }) async {
    try {
      final data = await _filter(
        _client.from(table).select(),
        where,
      ).limit(1).maybeSingle();
      return data == null ? null : Row.from(data);
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Row> insert(String table, Row row) async {
    try {
      final data = await _client.from(table).insert(row).select().single();
      return Row.from(data);
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Row>> insertMany(String table, List<Row> rows) async {
    try {
      final data = await _client.from(table).insert(rows).select();
      return data.map(Row.from).toList();
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Row> upsert(
    String table,
    Row row, {
    required List<String> onConflict,
  }) async {
    try {
      final data = await _client
          .from(table)
          .upsert(row, onConflict: onConflict.join(','))
          .select()
          .single();
      return Row.from(data);
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Row?> update(
    String table, {
    required Map<String, Object?> where,
    required Row values,
  }) async {
    try {
      final data = await _filter(
        _client.from(table).update(values),
        where,
      ).select().limit(1).maybeSingle();
      return data == null ? null : Row.from(data);
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> delete(
    String table, {
    required Map<String, Object?> where,
  }) async {
    try {
      await _filter(_client.from(table).delete(), where);
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ---- FileStorage (Supabase Storage) ----

  @override
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final storage = _client.storage.from(bucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      // Cambiamos el sufijo para evitar que el navegador sirva una foto vieja
      // desde caché cuando se reemplaza la imagen de una prenda.
      final url = storage.getPublicUrl(path);
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> remove({required String bucket, required String path}) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
