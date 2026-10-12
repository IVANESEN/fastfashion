import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/repositories.dart';
import '../datasource/database_client.dart';

class DbReminderRepository implements ReminderRepository {
  DbReminderRepository({required this._db});

  static const table = 'reminder_settings';

  final DatabaseClient _db;

  @override
  Future<ReminderSettings> load(String userId) async {
    final row = await _db.selectOne(table, where: {'user_id': userId});
    if (row == null) return ReminderSettings(userId: userId);
    return ReminderSettings.fromRow(row);
  }

  @override
  Future<ReminderSettings> save(ReminderSettings settings) async {
    final saved = await _db.upsert(
      table,
      settings.toRow(),
      onConflict: const ['user_id'],
    );
    return ReminderSettings.fromRow(saved);
  }
}
