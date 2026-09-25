import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/core/providers/router_provider.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/history_screen.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/movement_tile.dart';

import '../helpers/fakes.dart';

/// El historial navega con `context.push` al formulario, así que necesita un
/// `GoRouter` real: `context.pop` sobre un router inventado revienta.
///
/// Se sustituyen **los dos** repositorios. El de categorías importa porque
/// abrir el formulario de edición monta el selector de categorías, que si
/// usa el repositorio real construye un `AppDatabase` de verdad (y Drift avisa
/// por log de bases duplicadas).
late FakeMovementRepository movements;
late FakeCategoryRepository categories;

DateTime thisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

/// La ventana del test es de 800x600 y el historial es un `ListView` largo:
/// sin esto los grupos de abajo ni siquiera se construyen.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openHistory(WidgetTester tester) async {
  // `appRouterProvider` es un `Provider<GoRouter>` y `MaterialApp.router`
  // quiere un `RouterConfig`: hay que leerlo de un contenedor. No depende de
  // ningún otro provider, así que un contenedor aparte sirve.
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        movementRepositoryProvider.overrideWithValue(movements),
        categoryRepositoryProvider.overrideWithValue(categories),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: container.read(appRouterProvider),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Historial').last);
  await tester.pumpAndSettle();
}

/// `find.byTooltip` devuelve el `Tooltip`, no el `IconButton` que lo envuelve:
/// hay que subir al ancestro para poder mirar su `onPressed`.
Finder nextButton(WidgetTester tester) => find.ancestor(
  of: find.byTooltip('Mes siguiente'),
  matching: find.byType(IconButton),
);

void main() {
  final month = thisMonth();

  setUp(() {
    movements = FakeMovementRepository();
    categories = FakeCategoryRepository();
  });
  tearDown(() {
    movements.dispose();
    categories.dispose();
  });

  group('lista agrupada', () {
    testWidgets('muestra una cabecera por día y una fila por movimiento', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 25000, date: DateTime(month.year, month.month, 12), description: 'Almuerzo'),
        buildMovement(id: 2, amount: 8000, date: DateTime(month.year, month.month, 3), categoryId: 2, categoryName: 'Transporte'),
      ]);
      await openHistory(tester);

      // Dos cabeceras de día, en orden descendente.
      expect(find.text('12 ${_shortMonth(month.month)} ${month.year}'), findsOneWidget);
      expect(find.text('3 ${_shortMonth(month.month)} ${month.year}'), findsOneWidget);
      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('la cabecera muestra el subtotal de gastos del día', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 25000, date: DateTime(month.year, month.month, 12)),
        buildMovement(id: 2, amount: 8000, date: DateTime(month.year, month.month, 12)),
      ]);
      await openHistory(tester);

      expect(find.text('-\$33.000'), findsOneWidget);
    });

    testWidgets('la cabecera omite el subtotal cuando el día no tiene gastos', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 900000,
          date: DateTime(month.year, month.month, 12),
          type: MovementType.income,
        ),
      ]);
      await openHistory(tester);

      // Un día solo de ingresos no debe mostrar un "-0" colgando.
      expect(find.textContaining('-'), findsNothing);
      expect(find.text('+\$900.000'), findsOneWidget);
    });

    testWidgets('la fila usa la descripción como título y la categoría como subtítulo', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12, 14, 30),
          description: 'Almuerzo',
        ),
      ]);
      await openHistory(tester);

      expect(find.text('Almuerzo'), findsOneWidget);
      expect(find.textContaining('Comida · '), findsOneWidget);
      expect(find.textContaining('14:30'), findsOneWidget);
    });

    testWidgets('sin descripción, la categoría es el título y no se repite', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 25000, date: DateTime(month.year, month.month, 12)),
      ]);
      await openHistory(tester);

      expect(find.text('Comida'), findsOneWidget);
      expect(find.textContaining('Comida · '), findsNothing);
    });

    testWidgets('un ingreso se muestra en verde y con más', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 1200000,
          date: DateTime(month.year, month.month, 4),
          type: MovementType.income,
        ),
      ]);
      await openHistory(tester);

      expect(find.text('+\$1.200.000'), findsOneWidget);
    });
  });

  group('navegación', () {
    testWidgets('tocar una fila abre el formulario en modo edición', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 77, amount: 25000, date: DateTime(month.year, month.month, 12), description: 'Almuerzo'),
      ]);
      await openHistory(tester);

      await tester.tap(find.text('Almuerzo'));
      await tester.pumpAndSettle();

      // El formulario se abre precargado con el movimiento tocado.
      expect(find.text('Editar movimiento'), findsWidgets);
      expect(find.text('Almuerzo'), findsWidgets);
    });

    testWidgets('‹ retrocede un mes y filtra la lista', (tester) async {
      useTallScreen(tester);
      final previous = DateTime(month.year, month.month - 1);
      movements.emit([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 12)),
        buildMovement(id: 2, amount: 7000, date: DateTime(previous.year, previous.month, 9)),
        buildMovement(id: 3, amount: 3000, date: DateTime(previous.year, previous.month, 9)),
      ]);
      await openHistory(tester);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();

      // Dos movimientos en el mismo día: el subtotal de la cabecera no puede
      // confundirse con el monto de una fila.
      expect(find.text('-\$10.000'), findsOneWidget);
      expect(find.text('-\$1.000'), findsNothing);
    });

    testWidgets('‹ › avanzan y retroceden meses', (tester) async {
      useTallScreen(tester);
      await openHistory(tester);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      final previous = DateTime(month.year, month.month - 1);
      expect(find.text('${_monthName(previous.month)} ${previous.year}'), findsOneWidget);

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('${_monthName(month.month)} ${month.year}'), findsOneWidget);
    });

    testWidgets('el botón › está deshabilitado en el mes en curso', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      final next = tester.widget<IconButton>(nextButton(tester));
      expect(next.onPressed, isNull);
    });

    testWidgets('el botón › se habilita al retroceder y se vuelve a bloquear al volver', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(nextButton(tester)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(nextButton(tester)).onPressed,
        isNull,
      );
    });
  });

  group('estados', () {
    testWidgets('un mes sin movimientos muestra el estado vacío con acción', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      expect(find.text('Sin movimientos'), findsOneWidget);
      expect(find.textContaining('Este mes no tiene movimientos'), findsOneWidget);
      expect(find.text('Registrar movimiento'), findsOneWidget);
    });

    testWidgets('el mensaje del estado vacío nombra el mes al que se retreated', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();

      expect(find.text('Sin movimientos'), findsOneWidget);
      expect(
        find.textContaining('Mes anterior no tiene movimientos'),
        findsOneWidget,
      );
    });

    testWidgets('la acción del estado vacío abre el formulario de nuevo', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      await tester.tap(find.text('Registrar movimiento'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo movimiento'), findsWidgets);
    });

    testWidgets('un fallo del repositorio muestra un mensaje de error', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 12)),
      ]);
      await openHistory(tester);
      expect(find.text('-\$1.000'), findsNWidgets(2), reason: 'subtotal y fila');

      movements.emitError(StateError('fallo de base de datos'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo cargar el historial'), findsOneWidget);
      expect(find.byType(MovementTile), findsNothing);
    });
  });

  testWidgets('una nueva emisión actualiza la lista sin recrear la pantalla', (
    tester,
  ) async {
    useTallScreen(tester);
    await openHistory(tester);
    expect(find.text('Sin movimientos'), findsOneWidget);

    // Equivale a guardar un movimiento desde el formulario: el stream de
    // Drift emite y la pantalla se repinta.
    movements.emit([
      buildMovement(id: 9, amount: 15000, date: DateTime(month.year, month.month, 6), description: 'Café'),
      buildMovement(id: 10, amount: 5000, date: DateTime(month.year, month.month, 6), description: 'Pan'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Sin movimientos'), findsNothing);
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('-\$15.000'), findsOneWidget);
    expect(find.text('-\$20.000'), findsOneWidget, reason: 'subtotal del día');
  });
}

String _monthName(int m) => const [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
][m - 1];

String _shortMonth(int m) => const [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
][m - 1];
