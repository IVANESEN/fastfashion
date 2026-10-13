import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'data/app_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppBackend backend;
  try {
    backend = await AppBackend.create(AppConfig.fromEnvironment());
  } on Object catch (error, stack) {
    // Si Supabase no responde o las credenciales son inválidas, la app sigue
    // funcionando con la base local en lugar de quedarse en blanco.
    debugPrint('No se pudo iniciar el backend configurado: $error\n$stack');
    backend = await AppBackend.create(const AppConfig());
  }

  runApp(FastFashionApp(backend: backend));
}
