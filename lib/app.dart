import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/router_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/theme/app_theme.dart';

class PipeApp extends ConsumerWidget {
  const PipeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Pipe Finanzas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // `system` al arrancar, así la app responde al modo oscuro del
      // dispositivo; el botón del AppBar lo fija a mano después.
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      // Las barras del sistema se recalculan aquí, ya dentro del `MaterialApp`
      // y con el tema resuelto. Fijarlas una vez en `main()` las dejaba con
      // los valores del tema claro para siempre: en oscuro quedaba una barra
      // de navegación blanca con los iconos oscuros.
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child!,
        );
      },
    );
  }
}
