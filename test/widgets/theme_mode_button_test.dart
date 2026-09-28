import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/theme_mode_provider.dart';
import 'package:pipefinanzaspersonales/core/theme/app_colors.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/shared/widgets/theme_mode_button.dart';

/// La acción de modo oscuro del AppBar.
///
/// Lo que se verifica aquí no es el color del tema — eso lo comprueba
/// `text_contrast_test.dart` — sino que el botón **mande**: que al pulsarlo la
/// pantalla cambie de verdad, que el icono ofrezca el modo al que se va y no
/// el actual, y que mantener pulsado devuelva el control al sistema.
///
/// El caso que más se rompe es el del sistema en oscuro: el estado sigue
/// siendo `ThemeMode.system` mientras lo que hay en pantalla es oscuro, así
/// que alternar sobre el estado y no sobre lo que se ve dejaría el botón sin
/// efecto en el primer toque.
void main() {
  /// Monta lo mismo que monta `PipeApp`: los dos temas y el modo del provider.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ref.watch(themeModeProvider),
            home: const Scaffold(body: Center(child: ThemeModeButton())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void sistemaEn(WidgetTester tester, Brightness brillo) {
    tester.platformDispatcher.platformBrightnessTestValue = brillo;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  Color fondoActual(WidgetTester tester) => Theme.of(
    tester.element(find.byType(ThemeModeButton)),
  ).scaffoldBackgroundColor;

  Icon iconoActual(WidgetTester tester) =>
      tester.widget<Icon>(find.byType(Icon).last);

  testWidgets('con el sistema en claro arranca en claro y ofrece la luna', (
    tester,
  ) async {
    sistemaEn(tester, Brightness.light);
    await pumpApp(tester);

    expect(fondoActual(tester), AppColors.background);
    expect(iconoActual(tester).icon, Icons.dark_mode);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip).last).message,
      'Usar tema oscuro',
    );
  });

  testWidgets('un toque pone el tema oscuro y el icono pasa al sol', (
    tester,
  ) async {
    sistemaEn(tester, Brightness.light);
    await pumpApp(tester);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();

    expect(fondoActual(tester), AppColors.darkBackground);
    expect(iconoActual(tester).icon, Icons.light_mode);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip).last).message,
      'Usar tema claro',
    );
  });

  testWidgets('otro toque vuelve al tema claro', (tester) async {
    sistemaEn(tester, Brightness.light);
    await pumpApp(tester);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();

    expect(fondoActual(tester), AppColors.background);
    expect(iconoActual(tester).icon, Icons.dark_mode);
  });

  testWidgets('con el sistema en oscuro, un toque lo pone en claro', (
    tester,
  ) async {
    // El sistema está en oscuro pero el modo *declarado* sigue siendo
    // `system`: si el botón alternara sobre el estado en vez de sobre lo que
    // se ve, el primer toque volvería a oscuro y parecería no hacer nada.
    sistemaEn(tester, Brightness.dark);
    await pumpApp(tester);
    expect(fondoActual(tester), AppColors.darkBackground);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();

    expect(fondoActual(tester), AppColors.background);
    expect(iconoActual(tester).icon, Icons.dark_mode);
  });

  testWidgets('mantener pulsado devuelve el control al sistema', (
    tester,
  ) async {
    sistemaEn(tester, Brightness.light);
    await pumpApp(tester);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    expect(fondoActual(tester), AppColors.darkBackground);

    await tester.longPress(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();

    // El sistema está en claro: volver a `system` tiene que verse claro.
    expect(fondoActual(tester), AppColors.background);
  });

  testWidgets('el estado arranca y termina en system, sin persistir nada', (
    tester,
  ) async {
    // El provider es de memoria: al abrir la app se vuelve a `system`. Esto
    // fija ese comportamiento a propósito; si algún día se persiste la
    // preferencia, este test es el que hay que cambiar.
    sistemaEn(tester, Brightness.dark);
    await pumpApp(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ThemeModeButton)),
    );
    expect(container.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
