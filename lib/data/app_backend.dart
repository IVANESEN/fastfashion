import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../app/config/app_config.dart';
import '../domain/repositories/repositories.dart';
import 'local/key_value_store.dart';
import 'local/local_auth_repository.dart';
import 'local/local_database.dart';
import 'repositories/db_garment_repository.dart';
import 'repositories/db_outfit_repository.dart';
import 'repositories/db_reminder_repository.dart';
import 'supabase/supabase_auth_repository.dart';
import 'supabase/supabase_database_client.dart';
import 'weather/open_meteo_weather_repository.dart';

/// Conjunto de repositorios que usa la app.
///
/// Patrón **Abstract Factory**: [create] decide una sola vez entre la base
/// local y Supabase; el resto de la app solo ve las interfaces del dominio.
class AppBackend {
  const AppBackend({
    required this.kind,
    required this.auth,
    required this.garments,
    required this.outfits,
    required this.reminders,
    required this.weather,
  });

  /// `local` o `supabase`, para mostrarlo en Perfil.
  final String kind;
  final AuthRepository auth;
  final GarmentRepository garments;
  final OutfitRepository outfits;
  final ReminderRepository reminders;
  final WeatherRepository weather;

  bool get isLocal => kind == 'local';

  static Future<AppBackend> create(AppConfig config) {
    return config.useSupabase ? _supabase(config) : _local();
  }

  /// Backend en memoria para pruebas.
  static Future<AppBackend> inMemory({WeatherRepository? weather}) {
    return _local(store: MemoryKeyValueStore(), weather: weather);
  }

  static Future<AppBackend> _local({
    KeyValueStore? store,
    WeatherRepository? weather,
  }) async {
    final kv = store ?? await SharedPrefsStore.open();
    final db = LocalDatabase(kv);
    final auth = LocalAuthRepository(db: db, store: kv);
    final garments = DbGarmentRepository(db: db, storage: db);

    // Cuenta demo con clóset de ejemplo, solo la primera vez.
    final demo = await auth.ensureDemoAccount();
    if (demo != null) {
      await garments.addSamples(demo.id);
    }
    await auth.restoreSession();

    return AppBackend(
      kind: 'local',
      auth: auth,
      garments: garments,
      outfits: DbOutfitRepository(db: db),
      reminders: DbReminderRepository(db: db),
      weather: weather ?? OpenMeteoWeatherRepository(),
    );
  }

  static Future<AppBackend> _supabase(AppConfig config) async {
    await sb.Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
    final client = sb.Supabase.instance.client;
    final db = SupabaseDatabaseClient(client);
    final auth = SupabaseAuthRepository(client: client, db: db);
    await auth.restoreSession();

    return AppBackend(
      kind: 'supabase',
      auth: auth,
      garments: DbGarmentRepository(db: db, storage: db),
      outfits: DbOutfitRepository(db: db),
      reminders: DbReminderRepository(db: db),
      weather: OpenMeteoWeatherRepository(),
    );
  }
}
