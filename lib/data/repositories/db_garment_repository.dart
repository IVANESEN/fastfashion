import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/garment_category.dart';
import '../../domain/entities/garment_color.dart';
import '../../domain/entities/garment_style.dart';
import '../../domain/entities/sample_closet.dart';
import '../../domain/repositories/repositories.dart';
import '../datasource/database_client.dart';

/// Repositorio de prendas sobre cualquier [DatabaseClient] + [FileStorage].
class DbGarmentRepository implements GarmentRepository {
  DbGarmentRepository({
    required this._db,
    required this._storage,
    this._uuid = const Uuid(),
    this._clock = DateTime.now,
  });

  static const table = 'garments';
  static const bucket = 'garments';

  final DatabaseClient _db;
  final FileStorage _storage;
  final Uuid _uuid;
  final DateTime Function() _clock;

  @override
  Future<List<Garment>> list(String userId) async {
    final rows = await _db.select(
      table,
      where: {'user_id': userId},
      orderBy: 'created_at',
      descending: true,
    );
    return rows.map(Garment.fromRow).toList();
  }

  @override
  Future<Garment?> find(String userId, String id) async {
    final row = await _db.selectOne(
      table,
      where: {'user_id': userId, 'id': id},
    );
    return row == null ? null : Garment.fromRow(row);
  }

  @override
  Future<Garment> create({
    required String userId,
    required String name,
    required GarmentCategory category,
    required GarmentStyle style,
    required GarmentColor color,
    Uint8List? imageBytes,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const ValidationFailure('Ponle un nombre a la prenda.');
    }
    final id = _uuid.v4();
    final imageUrl = imageBytes == null
        ? null
        : await _storage.upload(
            bucket: bucket,
            path: '$userId/$id.jpg',
            bytes: imageBytes,
          );
    final garment = Garment(
      id: id,
      userId: userId,
      name: cleanName,
      category: category,
      style: style,
      color: color,
      imageUrl: imageUrl,
      createdAt: _clock(),
    );
    final saved = await _db.insert(table, garment.toRow());
    return Garment.fromRow(saved);
  }

  @override
  Future<Garment> update(Garment garment, {Uint8List? imageBytes}) async {
    final name = garment.name.trim();
    if (name.isEmpty) {
      throw const ValidationFailure('Ponle un nombre a la prenda.');
    }
    var next = garment.copyWith(name: name);
    if (imageBytes != null) {
      final url = await _storage.upload(
        bucket: bucket,
        path: '${garment.userId}/${garment.id}.jpg',
        bytes: imageBytes,
      );
      next = next.copyWith(imageUrl: url);
    }
    final row = next.toRow()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at');
    final saved = await _db.update(
      table,
      where: {'user_id': garment.userId, 'id': garment.id},
      values: row,
    );
    if (saved == null) throw const NotFoundFailure('Esa prenda ya no existe.');
    return Garment.fromRow(saved);
  }

  @override
  Future<void> delete(Garment garment) async {
    await _db.delete(
      table,
      where: {'user_id': garment.userId, 'id': garment.id},
    );
    if (garment.hasPhoto) {
      // Best-effort: si falla el borrado del archivo no bloqueamos al usuario.
      try {
        await _storage.remove(
          bucket: bucket,
          path: '${garment.userId}/${garment.id}.jpg',
        );
      } on Object {
        // ignorado a propósito
      }
    }
  }

  @override
  Future<void> markWorn(String userId, List<String> ids, DateTime when) async {
    for (final id in ids) {
      final garment = await find(userId, id);
      if (garment == null) continue;
      await _db.update(
        table,
        where: {'user_id': userId, 'id': id},
        values: {
          'wear_count': garment.wearCount + 1,
          'last_worn_at': when.toUtc().toIso8601String(),
        },
      );
    }
  }

  @override
  Future<int> addSamples(String userId) async {
    final now = _clock();
    final rows = <Row>[];
    for (var i = 0; i < SampleCloset.items.length; i++) {
      final s = SampleCloset.items[i];
      rows.add(
        Garment(
          id: _uuid.v4(),
          userId: userId,
          name: s.name,
          category: s.category,
          style: s.style,
          color: s.color,
          // Orden estable: la primera de la lista queda como la más reciente.
          createdAt: now.subtract(Duration(seconds: i)),
        ).toRow(),
      );
    }
    final saved = await _db.insertMany(table, rows);
    return saved.length;
  }
}
