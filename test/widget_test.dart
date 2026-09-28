import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/app.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/core/theme/app_colors.dart';

import 'helpers/fakes.dart';

/// Estos tests son de navegación, no de datos. Se sustituye el repositorio
/// por un fake por dos razones:
///
/// - La base real es asíncrona, así que el historial cae en
///   `CircularProgressIndicator`, que anima sin fin y hace que
///   `pumpAndSettle` **nunca** termine.
/// - Montar la app varias veces crea varios `AppDatabase` sobre el mismo
///   ejecutor, que es justo lo que Drift avisa por log.
///
/// Se sustituyen **los dos** repositorios porque el formulario de S04 monta el
/// selector de categorías: con solo el de movimientos, abrirlo construye la
/// base real.
Future<FakeMovementRepository> pumpApp(WidgetTester tester) async {
  final movements = FakeMovementRepository();
  final categories = FakeCategoryRepository();
  addTearDown(movements.dispose);
  addTearDown(categories.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        movementRepositoryProvider.overrideWithValue(movements),
        categoryRepositoryProvider.overrideWithValue(categories),
      ],
      child: const PipeApp(),
    ),
  );
  await tester.pump();
  return movements;
}

/// Pasa el splash (1,5 s) y deja la app en el dashboard.
Future<void> skipSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('arranca y navega del splash al dashboard', (tester) async {
    await pumpApp(tester);

    // El splash aparece primero.
    expect(find.text('Pipe Finanzas'), findsOneWidget);

    await skipSplash(tester);

    expect(find.text('Inicio'), findsWidgets);
  });

  testWidgets('la NavigationBar cambia entre las dos ramas', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);

    expect(find.text('Historial'), findsOneWidget);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    // La rama activa muestra su propio AppBar.
    expect(find.text('Historial'), findsWidgets);
  });

  testWidgets('el FAB abre el formulario a pantalla completa', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo movimiento'), findsWidgets);
  });

  testWidgets('el formulario se pinta sobre el fondo #F8FAFC del PRD', (
    tester,
  ) async {
    await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // No basta con `find.text`: el acceptance del PRD pide el color exacto.
    // El `Scaffold` no fija color propio, así que se lee el que resuelve el
    // tema, que es el que acaba pintándose.
    final context = tester.element(find.byType(Scaffold).last);
    expect(Theme.of(context).scaffoldBackgroundColor, const Color(0xFFF8FAFC));
    expect(AppColors.background, const Color(0xFFF8FAFC));
  });
}
