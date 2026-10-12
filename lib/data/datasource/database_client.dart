import 'dart:typed_data';

/// Fila de una tabla: mapa columna → valor JSON.
typedef Row = Map<String, dynamic>;

/// Acceso genérico a tablas, con la misma forma que PostgREST/Supabase.
///
/// Los repositorios de datos dependen **solo** de esta interfaz. Hoy hay dos
/// implementaciones intercambiables:
///
/// * `LocalDatabase` – base embebida y persistente (localStorage en web).
/// * `SupabaseDatabaseClient` – tablas reales de Supabase.
///
/// Los filtros `where` son de igualdad (equivalente a `.eq()` de Supabase).
abstract interface class DatabaseClient {
  Future<List<Row>> select(
    String table, {
    Map<String, Object?> where = const {},
    String? orderBy,
    bool descending = false,
    int? limit,
  });

  Future<Row?> selectOne(String table, {required Map<String, Object?> where});

  Future<Row> insert(String table, Row row);

  Future<List<Row>> insertMany(String table, List<Row> rows);

  /// Inserta, o actualiza si ya existe una fila con los mismos [onConflict].
  Future<Row> upsert(String table, Row row, {required List<String> onConflict});

  /// Actualiza las filas que cumplan [where]. Devuelve la primera actualizada.
  Future<Row?> update(
    String table, {
    required Map<String, Object?> where,
    required Row values,
  });

  Future<void> delete(String table, {required Map<String, Object?> where});
}

/// Almacenamiento de archivos (fotos de prendas).
abstract interface class FileStorage {
  /// Sube [bytes] y devuelve una URL que `Image.network`/`Image.memory`
  /// pueden mostrar.
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  });

  Future<void> remove({required String bucket, required String path});
}
