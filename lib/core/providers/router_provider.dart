import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/movements/presentation/screens/history_screen.dart';
import '../../features/movements/presentation/screens/movement_form_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_splash.dart';
import '../router/app_router.dart';
import '../router/placeholder_screens.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// S00 registró las pantallas con placeholders. S04–S06 los sustituyen sin
/// cambiar la forma del router: el formulario vive en el navegador raíz, fuera
/// del shell, para que al guardar se superponga y no deje las pestañas
/// desincronizadas.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppSplash(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardPlaceholder(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newMovement,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: MovementFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.movementById,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: MovementFormScreen(id: movementIdFrom(state)),
        ),
      ),
    ],
  );
});
