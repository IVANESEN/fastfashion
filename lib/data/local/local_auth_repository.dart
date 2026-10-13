import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../../core/validation/validators.dart';
import '../../domain/entities/demo_account.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../datasource/database_client.dart';
import 'key_value_store.dart';

/// Autenticación sobre la base local.
///
/// Las contraseñas se guardan con sal + SHA-256: suficiente para una base
/// de demostración en el navegador, **no** para producción. En producción
/// se usa `SupabaseAuthRepository` (Supabase Auth con bcrypt y JWT).
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required this._db,
    required this._store,
    this._uuid = const Uuid(),
    this._clock = DateTime.now,
  });

  static const usersTable = 'auth_users';
  static const profilesTable = 'profiles';
  static const _sessionKey = 'ff.session';

  final DatabaseClient _db;
  final KeyValueStore _store;
  final Uuid _uuid;
  final DateTime Function() _clock;
  final _controller = StreamController<UserProfile?>.broadcast();

  UserProfile? _current;

  @override
  UserProfile? get currentUser => _current;

  @override
  Stream<UserProfile?> get authChanges => _controller.stream;

  void _emit(UserProfile? user) {
    _current = user;
    _controller.add(user);
  }

  static String _hash(String salt, String password) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final id = _store.read(_sessionKey);
    if (id == null) return null;
    final row = await _db.selectOne(profilesTable, where: {'id': id});
    if (row == null) {
      await _store.remove(_sessionKey);
      return null;
    }
    final profile = UserProfile.fromRow(row);
    _current = profile;
    return profile;
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = Validators.normalizeEmail(email);
    final user = await _db.selectOne(usersTable, where: {'email': normalized});
    const generic = AuthFailure('Correo o contraseña incorrectos.');
    if (user == null) throw generic;
    final expected = user['password_hash'] as String? ?? '';
    final actual = _hash(user['salt'] as String? ?? '', password);
    if (expected != actual) throw generic;

    final profileRow = await _db.selectOne(
      profilesTable,
      where: {'id': user['id']},
    );
    if (profileRow == null) throw generic;
    final profile = UserProfile.fromRow(profileRow);
    await _store.write(_sessionKey, profile.id);
    _emit(profile);
    return profile;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final emailError = Validators.email(email);
    if (emailError != null) throw ValidationFailure(emailError);
    final passwordError = Validators.password(password);
    if (passwordError != null) throw ValidationFailure(passwordError);
    final nameError = Validators.name(displayName);
    if (nameError != null) throw ValidationFailure(nameError);

    final profile = await _createAccount(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _store.write(_sessionKey, profile.id);
    _emit(profile);
    return profile;
  }

  /// Inserta usuario + perfil sin iniciar sesión.
  Future<UserProfile> _createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalized = Validators.normalizeEmail(email);
    final existing = await _db.selectOne(
      usersTable,
      where: {'email': normalized},
    );
    if (existing != null) {
      throw const AuthFailure('Ese correo ya tiene una cuenta. Inicia sesión.');
    }

    final id = _uuid.v4();
    final salt = _uuid.v4();
    await _db.insert(usersTable, {
      'id': id,
      'email': normalized,
      'salt': salt,
      'password_hash': _hash(salt, password),
      'created_at': _clock().toUtc().toIso8601String(),
    });
    final profile = UserProfile(
      id: id,
      email: normalized,
      displayName: displayName.trim(),
      city: City.sanSalvador,
      createdAt: _clock(),
    );
    await _db.insert(profilesTable, profile.toRow());
    return profile;
  }

  @override
  Future<void> signOut() async {
    await _store.remove(_sessionKey);
    _emit(null);
  }

  @override
  Future<UserProfile> updateProfile({String? displayName, City? city}) async {
    final user = _current;
    if (user == null) throw const AuthFailure('Inicia sesión para continuar.');
    if (displayName != null) {
      final error = Validators.name(displayName);
      if (error != null) throw ValidationFailure(error);
    }
    final next = user.copyWith(displayName: displayName?.trim(), city: city);
    await _db.update(
      profilesTable,
      where: {'id': user.id},
      values: {'display_name': next.displayName, 'city': next.city.name},
    );
    _emit(next);
    return next;
  }

  /// Crea la cuenta demo si aún no existe. Devuelve su perfil, o `null` si ya
  /// existía (en cuyo caso no se toca nada). No inicia sesión.
  Future<UserProfile?> ensureDemoAccount() async {
    final existing = await _db.selectOne(
      usersTable,
      where: {'email': DemoAccount.email},
    );
    if (existing != null) return null;
    return _createAccount(
      email: DemoAccount.email,
      password: DemoAccount.password,
      displayName: DemoAccount.name,
    );
  }
}
