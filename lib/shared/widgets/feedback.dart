import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';

enum SnackBarKind { success, error, info }

/// §15 — SnackBar unificado. Los colores salen del `ThemeExtension` semántico
/// para que ningún widget importe `AppColors` directamente.
///
/// Si no hay `ScaffoldMessenger` (todavía no hay `Scaffold`, o la pantalla ya
/// se cerró) no hace nada: es mejor no mostrar nada que lanzar.
void showAppSnackBar(BuildContext context, String message, SnackBarKind kind) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final color = switch (kind) {
    SnackBarKind.success => context.semantic.income,
    SnackBarKind.error => context.semantic.expense,
    SnackBarKind.info => null,
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
