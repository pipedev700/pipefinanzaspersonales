import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/database/seed/default_categories.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/history_screen.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/day_header.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/movement_tile.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

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
  await pumpApp(
    tester,
    movements: movements,
    categories: categories,
    tab: 'Historial',
  );
}

/// `find.byTooltip` devuelve el `Tooltip`, no el `IconButton` que lo envuelve:
/// hay que subir al ancestro para poder mirar su `onPressed`.
Finder nextButton(WidgetTester tester) => find.ancestor(
  of: find.byTooltip('Mes siguiente'),
  matching: find.byType(IconButton),
);

/// Un mismo monto puede pintarse en la cabecera del día y en su fila. Estos
/// helpers acotan la búsqueda a cada widget para que los asserts describan
/// *dónde* se espera el número.
Finder inHeader(String text) =>
    find.descendant(of: find.byType(DayHeader), matching: find.text(text));

Finder inTile(String text) =>
    find.descendant(of: find.byType(MovementTile), matching: find.text(text));

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
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 8000,
          date: DateTime(month.year, month.month, 3),
          categoryId: 2,
          categoryName: 'Transporte',
        ),
      ]);
      await openHistory(tester);

      // Dos cabeceras de día, en orden descendente.
      expect(
        find.text('12 ${_shortMonth(month.month)} ${month.year}'),
        findsOneWidget,
      );
      expect(
        find.text('3 ${_shortMonth(month.month)} ${month.year}'),
        findsOneWidget,
      );
      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('la cabecera muestra el subtotal de gastos del día', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
        ),
        buildMovement(
          id: 2,
          amount: 8000,
          date: DateTime(month.year, month.month, 12),
        ),
      ]);
      await openHistory(tester);

      expect(find.text('-\$33.000'), findsOneWidget);
    });

    testWidgets('un día solo de ingresos muestra el saldo en verde con +', (
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

      // Un día solo de ingresos no debe mostrar un "-0" colgando, y su saldo
      // es el ingreso completo, en positivo.
      expect(find.textContaining('-'), findsNothing);
      expect(inHeader('+\$900.000'), findsOneWidget);
      expect(inTile('+\$900.000'), findsOneWidget);
    });

    testWidgets(
      'un día con ingresos y gastos muestra el saldo, no solo el gasto',
      (tester) async {
        useTallScreen(tester);
        movements.emit([
          buildMovement(
            id: 1,
            amount: 3000000,
            date: DateTime(month.year, month.month, 12),
            type: MovementType.income,
          ),
          buildMovement(
            id: 2,
            amount: 100000,
            date: DateTime(month.year, month.month, 12),
          ),
        ]);
        await openHistory(tester);

        // El defecto original: la cabecera pintaba "-$100.000" en rojo aunque el
        // día cerrara en +$2.900.000.
        expect(inHeader('+\$2.900.000'), findsOneWidget);
        expect(inHeader('\$100.000'), findsNothing);
        expect(
          find.byTooltip('Ingresos \$3.000.000 · Gastos \$100.000'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'la fila usa la descripción como título y la categoría como subtítulo',
      (tester) async {
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
      },
    );

    testWidgets('sin descripción, la categoría es el título y no se repite', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
        ),
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

      // El monto aparece dos veces (cabecera y fila); se busca dentro de cada
      // widget para no depender de cuántas veces se repita en pantalla.
      expect(inTile('+\$1.200.000'), findsOneWidget);
      expect(inHeader('+\$1.200.000'), findsOneWidget);
    });
  });

  group('navegación', () {
    testWidgets('tocar una fila abre el formulario en modo edición', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 77,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
          description: 'Almuerzo',
        ),
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
        buildMovement(
          id: 1,
          amount: 1000,
          date: DateTime(month.year, month.month, 12),
        ),
        buildMovement(
          id: 2,
          amount: 7000,
          date: DateTime(previous.year, previous.month, 9),
        ),
        buildMovement(
          id: 3,
          amount: 3000,
          date: DateTime(previous.year, previous.month, 9),
        ),
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
      expect(
        find.text('${_monthName(previous.month)} ${previous.year}'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(
        find.text('${_monthName(month.month)} ${month.year}'),
        findsOneWidget,
      );
    });

    testWidgets('el botón › está deshabilitado en el mes en curso', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      final next = tester.widget<IconButton>(nextButton(tester));
      expect(next.onPressed, isNull);
    });

    testWidgets(
      'el botón › se habilita al retroceder y se vuelve a bloquear al volver',
      (tester) async {
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
        expect(tester.widget<IconButton>(nextButton(tester)).onPressed, isNull);
      },
    );
  });

  group('estados', () {
    testWidgets('un mes sin movimientos muestra el estado vacío con acción', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      expect(find.text('Sin movimientos'), findsOneWidget);
      expect(
        find.textContaining('Este mes no tiene movimientos'),
        findsOneWidget,
      );
      expect(find.text('Registrar movimiento'), findsOneWidget);
    });

    testWidgets('el estado vacío no desborda en un móvil de 360x800', (
      tester,
    ) async {
      for (final scale in const [1.0, 1.3, 1.5]) {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await openHistory(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'el estado vacío desbordó con la fuente al $scale',
        );
        expect(find.text('Registrar movimiento'), findsOneWidget);
      }
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    });

    testWidgets(
      'el mensaje del estado vacío nombra el mes al que se retreated',
      (tester) async {
        useTallScreen(tester);
        await openHistory(tester);

        await tester.tap(find.byTooltip('Mes anterior'));
        await tester.pumpAndSettle();

        expect(find.text('Sin movimientos'), findsOneWidget);
        expect(
          find.textContaining('Mes anterior no tiene movimientos'),
          findsOneWidget,
        );
      },
    );

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
        buildMovement(
          id: 1,
          amount: 1000,
          date: DateTime(month.year, month.month, 12),
        ),
      ]);
      await openHistory(tester);
      expect(
        find.text('-\$1.000'),
        findsNWidgets(2),
        reason: 'subtotal y fila',
      );

      movements.emitError(StateError('fallo de base de datos'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo cargar el historial'), findsOneWidget);
      expect(find.byType(MovementTile), findsNothing);
    });
  });

  group('filtro por categoría', () {
    /// Abre la hoja y marca [category]. Se hace en dos pasos (marcar y cerrar)
    /// para que el test tapte lo mismo que el usuario.
    Future<void> filterBy(
      WidgetTester tester,
      String category, {
      bool close = true,
    }) async {
      await tester.tap(find.byTooltip('Filtrar por categoría'));
      await tester.pumpAndSettle();

      await tester.tap(inFilterSheet(category));
      await tester.pumpAndSettle();
      if (close) {
        await tester.tap(inFilterSheet('Ver 1 categoría'));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('la hoja lista el catálogo y dice que no hay filtro', (
      tester,
    ) async {
      useTallScreen(tester);
      await openHistory(tester);

      await tester.tap(find.byTooltip('Filtrar por categoría'));
      await tester.pumpAndSettle();

      expect(inFilterSheet('Filtrar por categoría'), findsOneWidget);
      expect(inFilterSheet('Mostrando todas las categorías'), findsOneWidget);
      // 2 gastos + 1 ingreso del catálogo de pruebas.
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(
        find.text('Limpiar'),
        findsNothing,
        reason: 'no hay nada que limpiar',
      );
    });

    testWidgets('marcar una categoría deja solo sus movimientos', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 8000,
          date: DateTime(month.year, month.month, 12),
          categoryId: 2,
          categoryName: 'Transporte',
          description: 'Bus',
        ),
      ]);
      await openHistory(tester);
      expect(find.byType(MovementTile), findsNWidgets(2));

      await filterBy(tester, 'Transporte');

      expect(find.byType(MovementTile), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);
      expect(find.text('Almuerzo'), findsNothing);
    });

    testWidgets('la lista se va filtrando mientras se elige, sin confirmar', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 8000,
          date: DateTime(month.year, month.month, 12),
          categoryId: 2,
          categoryName: 'Transporte',
          description: 'Bus',
        ),
      ]);
      await openHistory(tester);

      // La hoja sigue abierta: el filtro ya se ve aplicado detrás.
      await filterBy(tester, 'Transporte', close: false);

      expect(inFilterSheet('Ver 1 categoría'), findsOneWidget);
      expect(inFilterSheet('Mostrando 1 categoría'), findsOneWidget);
      expect(find.text('Almuerzo'), findsNothing);
    });

    testWidgets('el botón muestra cuántas categorías hay activas', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
        ),
      ]);
      await openHistory(tester);

      await filterBy(tester, 'Comida');

      expect(
        find.byTooltip('Filtrar por categoría (1 activas)'),
        findsOneWidget,
      );
      expect(find.text('1 categoría seleccionada'), findsOneWidget);
    });

    testWidgets('la barra activa quita el filtro sin abrir la hoja', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 8000,
          date: DateTime(month.year, month.month, 12),
          categoryId: 2,
          categoryName: 'Transporte',
          description: 'Bus',
        ),
      ]);
      await openHistory(tester);
      await filterBy(tester, 'Transporte');

      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();

      expect(find.byType(MovementTile), findsNWidgets(2));
      expect(find.text('1 categoría seleccionada'), findsNothing);
      expect(find.byTooltip('Filtrar por categoría'), findsOneWidget);
    });

    testWidgets(
      'un filtro sin coincidencias lo explica, no sale vacío a secas',
      (tester) async {
        useTallScreen(tester);
        movements.emit([
          buildMovement(
            id: 1,
            amount: 25000,
            date: DateTime(month.year, month.month, 12),
          ),
        ]);
        await openHistory(tester);

        // No hay ningún movimiento de "Salario" este mes.
        await filterBy(tester, 'Salario');

        expect(find.text('Sin movimientos'), findsOneWidget);
        expect(
          find.textContaining('No hay movimientos de las categorías elegidas'),
          findsOneWidget,
        );
      },
    );

    testWidgets('el filtro se conserva al cambiar de mes', (tester) async {
      useTallScreen(tester);
      final previous = DateTime(month.year, month.month - 1);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 8000,
          date: DateTime(previous.year, previous.month, 12),
          categoryId: 2,
          categoryName: 'Transporte',
          description: 'Bus',
        ),
      ]);
      await openHistory(tester);
      await filterBy(tester, 'Transporte');
      expect(find.text('Almuerzo'), findsNothing);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();

      // Sigue filtrando, y ahora sí encuentra el movimiento de Transporte.
      expect(find.text('1 categoría seleccionada'), findsOneWidget);
      expect(find.byType(MovementTile), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);
    });
  });

  /// Un móvil de verdad, 360x800: con las 16 categorías reales la hoja de
  /// filtro no cabe entera, y una columna de casillas sin tope de altura
  /// revienta con un `RenderFlex overflowed` que en el test de 1000x2400 no
  /// se ve. Aquí se comprueba que se abre, se hace scroll y se cierra limpio.
  group('en un móvil de 360x800', () {
    testWidgets('la hoja de filtro hace scroll y no desborda', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      categories = FakeCategoryRepository([
        for (var i = 0; i < defaultCategories.length; i++)
          buildCategory(
            id: i + 1,
            name: defaultCategories[i].name,
            iconKey: defaultCategories[i].iconKey,
            colorValue: defaultCategories[i].colorValue,
            type: defaultCategories[i].type,
            sortOrder: defaultCategories[i].sortOrder,
          ),
      ]);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: DateTime(month.year, month.month, 12),
          description: 'Almuerzo',
        ),
      ]);
      await openHistory(tester);

      await tester.tap(find.byTooltip('Filtrar por categoría'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Arriba están los gastos; los ingresos quedan por debajo.
      expect(inFilterSheet('GASTO'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(inFilterSheet('INGRESO'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Almuerzo'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
      buildMovement(
        id: 9,
        amount: 15000,
        date: DateTime(month.year, month.month, 6),
        description: 'Café',
      ),
      buildMovement(
        id: 10,
        amount: 5000,
        date: DateTime(month.year, month.month, 6),
        description: 'Pan',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Sin movimientos'), findsNothing);
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('-\$15.000'), findsOneWidget);
    expect(find.text('-\$20.000'), findsOneWidget, reason: 'subtotal del día');
  });
}

String _monthName(int m) => const [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
][m - 1];

String _shortMonth(int m) => const [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
][m - 1];
