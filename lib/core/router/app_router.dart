import 'package:go_router/go_router.dart';

/// §27 — Rutas centralizadas. Nunca escribir literales de ruta en un widget.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const dashboard = '/';
  static const history = '/historial';
  static const historical = '/historico';
  static const newMovement = '/movimiento/nuevo';
  static const movementById = '/movimiento/:id';

  static String editMovementPath(String id) => '/movimiento/$id';
}

/// Acceso tipado al parámetro de ruta.
int? movementIdFrom(GoRouterState state) {
  final raw = state.pathParameters['id'];
  return raw == null ? null : int.tryParse(raw);
}
