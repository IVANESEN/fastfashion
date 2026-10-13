import 'package:fastfashion/app/routes.dart';
import 'package:fastfashion/core/layout/responsive.dart';
import 'package:fastfashion/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Tamaños de teléfono representativos para las pruebas de responsividad.
const kPhoneSizes = <Size>[
  Size(320, 568), // iPhone SE 1.ª gen / Android compacto
  Size(360, 640), // Android común
  Size(390, 844), // iPhone 12–15
  Size(430, 932), // iPhone Pro Max
];

/// Monta [screen] en un router mínimo. Las demás rutas de la app muestran un
/// texto `ruta:<path>` para poder comprobar a dónde navegó la pantalla.
Future<GoRouter> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<SingleChildWidget> providers = const [],
  Size size = const Size(390, 844),
  double textScale = 1,
  String path = '/',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget stub(String p) => Scaffold(body: Center(child: Text('ruta:$p')));

  final others = <String>{
    AppRoutes.welcome,
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.today,
    AppRoutes.closet,
    AppRoutes.assistant,
    AppRoutes.reminders,
    AppRoutes.addGarment,
    AppRoutes.profile,
  }..remove(path);

  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: path, builder: (_, _) => screen),
      for (final p in others) GoRoute(path: p, builder: (_, _) => stub(p)),
      GoRoute(
        path: AppRoutes.garmentPattern,
        builder: (_, state) =>
            stub('/closet/item/${state.pathParameters['id']}'),
      ),
    ],
  );

  final app = MaterialApp.router(
    theme: AppTheme.light(),
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: AppFrame(child: child!),
    ),
  );

  await tester.pumpWidget(
    providers.isEmpty ? app : MultiProvider(providers: providers, child: app),
  );
  await tester.pump();
  return router;
}
