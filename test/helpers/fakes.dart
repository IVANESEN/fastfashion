import 'dart:typed_data';

import 'package:fastfashion/data/app_backend.dart';
import 'package:fastfashion/domain/entities/demo_account.dart';
import 'package:fastfashion/domain/entities/user_profile.dart';
import 'package:fastfashion/domain/entities/weather_snapshot.dart';
import 'package:fastfashion/domain/repositories/repositories.dart';
import 'package:fastfashion/features/auth/auth_controller.dart';
import 'package:fastfashion/features/closet/closet_controller.dart';
import 'package:fastfashion/features/closet/photo_picker.dart';
import 'package:fastfashion/features/today/today_controller.dart';
import 'package:fastfashion/features/today/weather_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Cede el control varias veces para que terminen las cadenas de `await`.
///
/// Solo usa microtareas: funciona tanto en `test` como bajo el reloj falso de
/// `testWidgets` (donde `Future.delayed` no avanza sin `pump`).
Future<void> settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.microtask(() {});
  }
}

/// Día fijo de las pruebas: viernes 9 de octubre de 2026, 8:00 a. m.
final kTestNow = DateTime(2026, 10, 9, 8);

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

/// Clima controlado por la prueba.
class FakeWeatherRepository implements WeatherRepository {
  FakeWeatherRepository(this.snapshot);

  WeatherSnapshot snapshot;
  int calls = 0;

  static WeatherSnapshot mild() => WeatherSnapshot(
    cityName: 'San Salvador',
    temperatureC: 24,
    rainProbability: 10,
    fetchedAt: kTestNow,
  );

  static WeatherSnapshot rainy() => WeatherSnapshot(
    cityName: 'San Salvador',
    temperatureC: 29,
    rainProbability: 80,
    rainExpectedAt: DateTime(2026, 10, 9, 16),
    fetchedAt: kTestNow,
  );

  @override
  Future<WeatherSnapshot> current(City city) async {
    calls++;
    return snapshot;
  }
}

/// Backend en memoria con todos los controladores cableados.
class TestApp {
  TestApp._({
    required this.backend,
    required this.auth,
    required this.closet,
    required this.weather,
    required this.today,
    required this.picker,
    required this.weatherRepo,
  });

  final AppBackend backend;
  final AuthController auth;
  final ClosetController closet;
  final WeatherController weather;
  final TodayController today;
  final FakePhotoPicker picker;
  final FakeWeatherRepository weatherRepo;

  /// Sesión con la cuenta demo (clóset de ejemplo).
  static Future<TestApp> demo({WeatherSnapshot? weather}) async {
    final repo = FakeWeatherRepository(weather ?? FakeWeatherRepository.mild());
    final backend = await AppBackend.inMemory(weather: repo);
    await backend.auth.signIn(
      email: DemoAccount.email,
      password: DemoAccount.password,
    );
    return _build(backend, repo);
  }

  /// Usuario nuevo con clóset vacío.
  static Future<TestApp> empty({WeatherSnapshot? weather}) async {
    final repo = FakeWeatherRepository(weather ?? FakeWeatherRepository.mild());
    final backend = await AppBackend.inMemory(weather: repo);
    await backend.auth.signUp(
      email: 'nuevo@correo.com',
      password: 'secreto1',
      displayName: 'Nuevo Usuario',
    );
    return _build(backend, repo);
  }

  static Future<TestApp> _build(
    AppBackend backend,
    FakeWeatherRepository repo,
  ) async {
    final auth = AuthController(backend.auth);
    final closet = ClosetController(repository: backend.garments, auth: auth);
    final weather = WeatherController(repository: backend.weather, auth: auth);
    await closet.load();
    await weather.refresh();
    final today = TodayController(
      closet: closet,
      weather: weather,
      outfits: backend.outfits,
      garments: backend.garments,
      auth: auth,
      clock: () => kTestNow,
    );
    // Deja que `_restoreToday` termine.
    await settle();
    return TestApp._(
      backend: backend,
      auth: auth,
      closet: closet,
      weather: weather,
      today: today,
      picker: FakePhotoPicker(),
      weatherRepo: repo,
    );
  }

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<AuthController>.value(value: auth),
    ChangeNotifierProvider<ClosetController>.value(value: closet),
    ChangeNotifierProvider<WeatherController>.value(value: weather),
    ChangeNotifierProvider<TodayController>.value(value: today),
    Provider<PhotoPicker>.value(value: picker),
  ];

  void dispose() {
    today.dispose();
    weather.dispose();
    closet.dispose();
    auth.dispose();
  }
}
