import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/app_backend.dart';
import '../features/assistant/assistant_controller.dart';
import '../features/auth/auth_controller.dart';
import '../features/closet/closet_controller.dart';
import '../features/closet/photo_picker.dart';
import '../features/reminders/reminders_controller.dart';
import '../features/today/today_controller.dart';
import '../features/today/weather_controller.dart';

/// Raíz de inyección de dependencias.
///
/// Los repositorios vienen del [AppBackend] (Factory) y cada controlador
/// (ViewModel) recibe solo lo que necesita. Ningún widget crea servicios.
class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.backend,
    required this.child,
    this.photoPicker,
    super.key,
  });

  final AppBackend backend;
  final Widget child;

  /// Reemplazable en pruebas.
  final PhotoPicker? photoPicker;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppBackend>.value(value: backend),
        Provider<PhotoPicker>.value(
          value: photoPicker ?? ImagePickerPhotoPicker(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(backend.auth),
        ),
        ChangeNotifierProvider<ClosetController>(
          lazy: false,
          create: (c) => ClosetController(
            repository: backend.garments,
            auth: c.read<AuthController>(),
          ),
        ),
        ChangeNotifierProvider<WeatherController>(
          lazy: false,
          create: (c) => WeatherController(
            repository: backend.weather,
            auth: c.read<AuthController>(),
          ),
        ),
        ChangeNotifierProvider<RemindersController>(
          lazy: false,
          create: (c) => RemindersController(
            repository: backend.reminders,
            auth: c.read<AuthController>(),
          ),
        ),
        ChangeNotifierProvider<TodayController>(
          lazy: false,
          create: (c) => TodayController(
            closet: c.read<ClosetController>(),
            weather: c.read<WeatherController>(),
            outfits: backend.outfits,
            garments: backend.garments,
            auth: c.read<AuthController>(),
          ),
        ),
        ChangeNotifierProvider<AssistantController>(
          create: (c) => AssistantController(
            closet: c.read<ClosetController>(),
            weather: c.read<WeatherController>(),
            today: c.read<TodayController>(),
            auth: c.read<AuthController>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
