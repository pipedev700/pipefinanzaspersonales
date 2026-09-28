import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Splash del PRD. Muestra el logo y navega a la primera pantalla.
/// No depende de la base de datos: por eso vive en `shared/`.
class AppSplash extends StatefulWidget {
  const AppSplash({super.key});

  @override
  State<AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<AppSplash> {
  static const _visibleFor = Duration(milliseconds: 1500);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_visibleFor, () {
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Sin `backgroundColor` explícito: el del `Scaffold` viene del tema, y
      // así el splash respeta el modo oscuro. Poner aquí el color claro
      // dejaba un destello blanco al arrancar en oscuro.
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_mark.png', height: 96),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pipe Finanzas',
              // El navy de marca es casi negro: sobre el fondo oscuro
              // desaparecería, así que en oscuro se usa el color de texto.
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onSurface
                    : AppColors.brandNavy,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
