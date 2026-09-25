import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_splash.dart';
import '../router/app_router.dart';
import '../router/placeholder_screens.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// S00 — Registra las pantallas con placeholders. S04–S06 sustituyen los
/// placeholders por las implementaciones reales sin cambiar la forma
/// del router: el formulario vive fuera del shell para que al guardar
/// se superponga y no deje pestañas desincronizadas.
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
                builder: (context, state) => const HistoryPlaceholder(),
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
          child: MovementFormPlaceholder(),
        ),
      ),
      GoRoute(
        path: AppRoutes.movementById,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: MovementFormPlaceholder(id: movementIdFrom(state)),
        ),
      ),
    ],
  );
});
