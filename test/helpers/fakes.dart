import 'dart:typed_data';

import 'package:fastfashion/data/app_backend.dart';
import 'package:fastfashion/domain/entities/demo_account.dart';
import 'package:fastfashion/features/auth/auth_controller.dart';
import 'package:fastfashion/features/closet/closet_controller.dart';
import 'package:fastfashion/features/closet/photo_picker.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Selector de fotos que devuelve bytes fijos (o `null` = cancelado).
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.result]);

  Uint8List? result;
  PhotoSource? lastSource;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    lastSource = source;
    return result;
  }
}

/// Backend en memoria con sesión de la cuenta demo ya iniciada.
class TestApp {
  TestApp._(this.backend, this.auth, this.closet, this.picker);

  final AppBackend backend;
  final AuthController auth;
  final ClosetController closet;
  final FakePhotoPicker picker;

  static Future<TestApp> demo() async {
    final backend = await AppBackend.inMemory();
    await backend.auth.signIn(
      email: DemoAccount.email,
      password: DemoAccount.password,
    );
    return _build(backend);
  }

  /// Usuario nuevo con clóset vacío.
  static Future<TestApp> empty() async {
    final backend = await AppBackend.inMemory();
    await backend.auth.signUp(
      email: 'nuevo@correo.com',
      password: 'secreto1',
      displayName: 'Nuevo Usuario',
    );
    return _build(backend);
  }

  static Future<TestApp> _build(AppBackend backend) async {
    final auth = AuthController(backend.auth);
    final closet = ClosetController(repository: backend.garments, auth: auth);
    await closet.load();
    return TestApp._(backend, auth, closet, FakePhotoPicker());
  }

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<AuthController>.value(value: auth),
    ChangeNotifierProvider<ClosetController>.value(value: closet),
    Provider<PhotoPicker>.value(value: picker),
  ];

  void dispose() {
    closet.dispose();
    auth.dispose();
  }
}
