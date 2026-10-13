import 'dart:typed_data';

import '../entities/garment.dart';
import '../entities/garment_category.dart';
import '../entities/garment_color.dart';
import '../entities/garment_style.dart';
import '../entities/outfit.dart';
import '../entities/reminder_settings.dart';
import '../entities/user_profile.dart';
import '../entities/weather_snapshot.dart';

/// Contratos del dominio (patrón Repository).
///
/// La UI y los controladores solo conocen estas interfaces. Las
/// implementaciones concretas (base local o Supabase) viven en `data/` y se
/// eligen en un único lugar: `AppBackend` (patrón Factory).

abstract interface class AuthRepository {
  /// Usuario con sesión activa, o `null`.
  UserProfile? get currentUser;

  /// Emite cada cambio de sesión (login, logout, actualización de perfil).
  Stream<UserProfile?> get authChanges;

  /// Restaura la sesión guardada al abrir la app.
  Future<UserProfile?> restoreSession();

  Future<UserProfile> signIn({required String email, required String password});

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<UserProfile> updateProfile({String? displayName, City? city});
}

abstract interface class GarmentRepository {
  Future<List<Garment>> list(String userId);

  Future<Garment?> find(String userId, String id);

  Future<Garment> create({
    required String userId,
    required String name,
    required GarmentCategory category,
    required GarmentStyle style,
    required GarmentColor color,
    Uint8List? imageBytes,
  });

  /// Actualiza los campos editables. Si [imageBytes] no es nulo reemplaza la foto.
  Future<Garment> update(Garment garment, {Uint8List? imageBytes});

  Future<void> delete(Garment garment);

  /// Suma un uso y fija la fecha de último uso en cada prenda de [ids].
  Future<void> markWorn(String userId, List<String> ids, DateTime when);

  /// Agrega un clóset de ejemplo. Devuelve cuántas prendas creó.
  Future<int> addSamples(String userId);
}

abstract interface class OutfitRepository {
  Future<List<OutfitRecord>> history(String userId, {int limit = 30});

  Future<OutfitRecord?> forDate(String userId, String date);

  /// Guarda el outfit del día. Si ya existía uno para esa fecha lo reemplaza.
  Future<OutfitRecord> saveForDate({
    required String userId,
    required String date,
    required OutfitProposal proposal,
  });
}

abstract interface class ReminderRepository {
  Future<ReminderSettings> load(String userId);

  Future<ReminderSettings> save(ReminderSettings settings);
}

abstract interface class WeatherRepository {
  Future<WeatherSnapshot> current(City city);
}
