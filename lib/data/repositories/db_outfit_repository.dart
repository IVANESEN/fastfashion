import 'package:uuid/uuid.dart';

import '../../domain/entities/outfit.dart';
import '../../domain/repositories/repositories.dart';
import '../datasource/database_client.dart';

class DbOutfitRepository implements OutfitRepository {
  DbOutfitRepository({
    required this._db,
    this._uuid = const Uuid(),
    this._clock = DateTime.now,
  });

  static const table = 'outfits';

  final DatabaseClient _db;
  final Uuid _uuid;
  final DateTime Function() _clock;

  @override
  Future<List<OutfitRecord>> history(String userId, {int limit = 30}) async {
    final rows = await _db.select(
      table,
      where: {'user_id': userId},
      orderBy: 'outfit_date',
      descending: true,
      limit: limit,
    );
    return rows.map(OutfitRecord.fromRow).toList();
  }

  @override
  Future<OutfitRecord?> forDate(String userId, String date) async {
    final row = await _db.selectOne(
      table,
      where: {'user_id': userId, 'outfit_date': date},
    );
    return row == null ? null : OutfitRecord.fromRow(row);
  }

  @override
  Future<OutfitRecord> saveForDate({
    required String userId,
    required String date,
    required OutfitProposal proposal,
  }) async {
    final record = OutfitRecord(
      id: _uuid.v4(),
      userId: userId,
      date: date,
      topId: proposal.top.id,
      bottomId: proposal.bottom.id,
      shoesId: proposal.shoes?.id,
      jacketId: proposal.jacket?.id,
      title: proposal.title,
      occasion: proposal.occasion,
      style: proposal.style,
      createdAt: _clock(),
    );
    final saved = await _db.upsert(
      table,
      record.toRow(),
      onConflict: const ['user_id', 'outfit_date'],
    );
    return OutfitRecord.fromRow(saved);
  }
}
