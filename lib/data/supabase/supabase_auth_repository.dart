import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_failure.dart';
import '../../core/validation/validators.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../datasource/database_client.dart';
import 'supabase_database_client.dart';

/// Autenticación con Supabase Auth. El perfil público vive en `profiles`
/// (se crea con un trigger; ver `supabase/schema.sql`).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this._client, required this._db}) {
    // Si la sesión expira o se cierra desde otra pestaña, lo reflejamos.
    _subscription = _client.auth.onAuthStateChange.listen((state) {
      if (state.event == sb.AuthChangeEvent.signedOut && _current != null) {
        _emit(null);
      }
    });
  }

  static const profilesTable = 'profiles';

  final sb.SupabaseClient _client;
  final DatabaseClient _db;
  final _controller = StreamController<UserProfile?>.broadcast();
  late final StreamSubscription<sb.AuthState> _subscription;

  UserProfile? _current;

  @override
  UserProfile? get currentUser => _current;

  @override
  Stream<UserProfile?> get authChanges => _controller.stream;

  void _emit(UserProfile? user) {
    _current = user;
    _controller.add(user);
  }

  Future<UserProfile> _loadProfile(sb.User user, {String? fallbackName}) async {
    final row = await _db.selectOne(profilesTable, where: {'id': user.id});
    if (row != null) return UserProfile.fromRow(row);

    // El trigger no corrió (o aún no): creamos el perfil desde el cliente.
    final profile = UserProfile(
      id: user.id,
      email: user.email ?? '',
      displayName:
          fallbackName ??
          (user.userMetadata?['display_name'] as String?) ??
          (user.email ?? 'Usuario').split('@').first,
      city: City.sanSalvador,
      createdAt: DateTime.now(),
    );
    final saved = await _db.upsert(
      profilesTable,
      profile.toRow(),
      onConflict: const ['id'],
    );
    return UserProfile.fromRow(saved);
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final profile = await _loadProfile(user);
      _current = profile;
      return profile;
    } on AppFailure {
      return null;
    }
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: Validators.normalizeEmail(email),
        password: password,
      );
      final user = res.user;
      if (user == null) throw const AuthFailure('No pudimos iniciar sesión.');
      final profile = await _loadProfile(user);
      _emit(profile);
      return profile;
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
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

    try {
      final res = await _client.auth.signUp(
        email: Validators.normalizeEmail(email),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      final user = res.user;
      if (user == null) throw const AuthFailure('No pudimos crear tu cuenta.');
      if (res.session == null) {
        // Proyecto con confirmación de correo activada.
        throw const AuthFailure(
          'Te enviamos un correo para confirmar tu cuenta. '
          'Ábrelo y luego inicia sesión.',
        );
      }
      final profile = await _loadProfile(
        user,
        fallbackName: displayName.trim(),
      );
      _emit(profile);
      return profile;
    } on Object catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on Object {
      // Aun si falla la red, cerramos la sesión localmente.
    }
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

  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_controller.close());
  }
}
