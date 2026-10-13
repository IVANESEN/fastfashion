import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/assistant_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/closet/add_garment_screen.dart';
import '../features/closet/closet_screen.dart';
import '../features/closet/garment_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/today/today_screen.dart';
import 'routes.dart';
import 'shell.dart';

/// Construye el router con guardas de sesión.
///
/// * Sin sesión solo se ven Bienvenida, Iniciar sesión y Crear cuenta.
/// * Con sesión esas tres redirigen a Hoy.
/// * Las pestañas conservan su estado (scroll, filtros) al cambiar de una a
///   otra gracias a `StatefulShellRoute.indexedStack`.
GoRouter createRouter({
  required AuthController auth,
  GlobalKey<NavigatorState>? rootNavigatorKey,
}) {
  final rootKey = rootNavigatorKey ?? GlobalKey<NavigatorState>();
  const publicRoutes = {AppRoutes.welcome, AppRoutes.login, AppRoutes.signup};

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: auth.isSignedIn ? AppRoutes.today : AppRoutes.welcome,
    refreshListenable: auth,
    redirect: (context, state) {
      final isPublic = publicRoutes.contains(state.matchedLocation);
      if (!auth.isSignedIn && !isPublic) return AppRoutes.welcome;
      if (auth.isSignedIn && isPublic) return AppRoutes.today;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.today),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignUpScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (_, _) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.closet,
                builder: (_, _) => const ClosetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assistant,
                builder: (_, _) => const AssistantScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reminders,
                builder: (_, _) => const RemindersScreen(),
              ),
            ],
          ),
        ],
      ),
      // Pantallas completas: se dibujan sobre la barra inferior.
      GoRoute(
        path: AppRoutes.addGarment,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const AddGarmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.garmentPattern,
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            GarmentDetailScreen(garmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ProfileScreen(),
      ),
    ],
  );
}
