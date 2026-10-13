import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/layout/responsive.dart';
import '../core/theme/app_theme.dart';
import '../data/app_backend.dart';
import '../features/auth/auth_controller.dart';
import '../features/closet/photo_picker.dart';
import '../features/reminders/reminder_watcher.dart';
import 'app_providers.dart';
import 'router.dart';
import 'routes.dart';

/// Aplicación FastFashion.
class FastFashionApp extends StatelessWidget {
  const FastFashionApp({required this.backend, this.photoPicker, super.key});

  final AppBackend backend;

  /// Reemplazable en pruebas.
  final PhotoPicker? photoPicker;

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      backend: backend,
      photoPicker: photoPicker,
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter _router = createRouter(
    auth: context.read<AuthController>(),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FastFashion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: _router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          // Respeta el texto grande del sistema, con un tope que mantiene el
          // diseño usable.
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.4,
            ),
          ),
          child: AppFrame(
            child: ReminderWatcher(
              messengerKey: _messengerKey,
              onOpenToday: () => _router.go(AppRoutes.today),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
