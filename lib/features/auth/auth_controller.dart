import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';

/// Estado de sesión para la UI (ViewModel del patrón MVVM).
class AuthController extends ChangeNotifier {
  AuthController(this._repo) : _user = _repo.currentUser {
    _subscription = _repo.authChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<UserProfile?> _subscription;

  UserProfile? _user;
  bool _busy = false;
  String? _error;

  UserProfile? get user => _user;
  bool get isSignedIn => _user != null;
  bool get busy => _busy;

  /// Último error legible para el usuario; se limpia al reintentar.
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) {
    return _run(() => _repo.signIn(email: email, password: password));
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => _repo.signUp(email: email, password: password, displayName: name),
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<bool> updateProfile({String? displayName, City? city}) {
    return _run(
      () => _repo.updateProfile(displayName: displayName, city: city),
    );
  }

  Future<bool> _run(Future<UserProfile> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      return true;
    } on AppFailure catch (e) {
      _error = e.message;
      return false;
    } on Object {
      _error = const UnknownFailure().message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
