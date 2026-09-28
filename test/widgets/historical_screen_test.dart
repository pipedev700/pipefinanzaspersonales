import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/features/historical/presentation/screens/historical_screen.dart';
import 'package:pipefinanzaspersonales/features/historical/providers/historical_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/providers/history_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/history_screen.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/movement_tile.dart';
import 'package:pipefinanzaspersonales/shared/widgets/app_scaffold.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// La tercera pestaña: consulta por rango de fechas.
///
/// Los movimientos se sitúan en fechas relativas a hoy porque el rango por
/// defecto son los últimos 90 días: con fechas fijas el test empezaría a fallar
/// solo, según el día en que se ejecute.
late FakeMovementRepository movements;
late FakeCategoryRepository categories;

/// `hoy - days`, a medianoche.
DateTime daysAgo(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days);
}

void main() {
  setUp(() {
    movements = FakeMovementRepository();
    categories = FakeCategoryRepository();
  });
  tearDown(() {
    movements.dispose();
    categories.dispose();
  });

  group('la pestaña', () {
    testWidgets('existe como tercera destino y abre el histórico', (
      tester,
    ) async {
      await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );

      expect(find.byType(HistoricalScreen), findsOneWidget);
      expect(find.byType(AppScaffold), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });

    testWidgets('arranca con el rango de los últimos 90 días', (tester) async {
      await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );

      expect(find.textContaining('90 días'), findsOneWidget);
      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('Hasta'), findsOneWidget);
    });
  });

  group('lista por rango', () {
    testWidgets('muestra los movimientos del rango agrupados por día', (
      tester,
    ) async {
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: daysAgo(1),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 8000,
          date: daysAgo(1),
          description: 'Bus',
        ),
        buildMovement(
          id: 3,
          amount: 5000,
          date: daysAgo(10),
          description: 'Café',
        ),
        // Fuera del rango por defecto: no debe aparecer.
        buildMovement(
          id: 4,
          amount: 999999,
          date: daysAgo(200),
          description: 'Viejo',
        ),
      ]);
      await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );

      expect(find.byType(MovementTile), findsNWidgets(3));
      expect(find.text('Viejo'), findsNothing);
    });

    testWidgets('un rango sin movimientos muestra "Sin resultados"', (
      tester,
    ) async {
      movements.emit([buildMovement(id: 1, amount: 25000, date: daysAgo(200))]);
      await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(
        find.text('No hay movimientos registrados en ese rango de fechas.'),
        findsOneWidget,
      );
    });

    testWidgets('el estado vacío no desborda en un móvil de 360x800', (
      tester,
    ) async {
      for (final scale in const [1.0, 1.3, 1.5]) {
        await pumpApp(
          tester,
          movements: movements,
          categories: categories,
          tab: 'Histórico',
          size: const Size(360, 800),
        );
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'el estado vacío desbordó con la fuente al $scale',
        );
        expect(find.text('Sin resultados'), findsOneWidget);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
    });

    testWidgets('acortar el rango recorta la lista', (tester) async {
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: daysAgo(1),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 5000,
          date: daysAgo(80),
          description: 'Café',
        ),
      ]);
      final container = await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );
      expect(find.byType(MovementTile), findsNWidgets(2));

      container.read(historyRangeProvider.notifier).set(daysAgo(5), daysAgo(0));
      await tester.pumpAndSettle();

      expect(find.byType(MovementTile), findsOneWidget);
      expect(find.text('Café'), findsNothing);
      expect(find.textContaining('6 días'), findsOneWidget);
    });

    testWidgets('"Restablecer" devuelve el rango de 90 días', (tester) async {
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: daysAgo(1),
          description: 'Almuerzo',
        ),
        buildMovement(
          id: 2,
          amount: 5000,
          date: daysAgo(80),
          description: 'Café',
        ),
      ]);
      final container = await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );
      container.read(historyRangeProvider.notifier).set(daysAgo(5), daysAgo(0));
      await tester.pumpAndSettle();
      expect(find.byType(MovementTile), findsOneWidget);

      await tester.tap(find.text('Restablecer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('90 días'), findsOneWidget);
      expect(find.byType(MovementTile), findsNWidgets(2));
    });
  });

  group('totales del rango', () {
    testWidgets('el balance descuenta ingresos y gastos, con signo y color', (
      tester,
    ) async {
      movements.emit([
        buildMovement(
          id: 1,
          amount: 900000,
          date: daysAgo(2),
          type: MovementType.income,
        ),
        buildMovement(id: 2, amount: 15000, date: daysAgo(1)),
      ]);
      await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );

      expect(find.text('Balance del rango'), findsOneWidget);
      expect(find.text(r'+$885.000'), findsOneWidget);
      expect(find.text(r'$900.000'), findsOneWidget);
      expect(find.text(r'$15.000'), findsOneWidget);
    });

    testWidgets('un rango que cierra en negativo lo muestra con el signo', (
      tester,
    ) async {
      movements.emit([buildMovement(id: 1, amount: 15000, date: daysAgo(1))]);
      await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );

      // El mismo número aparece en el balance, en la cabecera del día y en la
      // fila; aquí se comprueba el del balance, que es el único envuelto en el
      // `Semantics` con su etiqueta.
      final balance = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Balance del rango',
      );
      expect(balance, findsOneWidget);
      expect(
        find.descendant(of: balance, matching: find.text(r'-$15.000')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Balance del rango'),
        findsOneWidget,
        reason: 'el balance se anuncia como negativo, no como un gasto más',
      );
    });
  });

  group('filtro de categorías', () {
    testWidgets(
      'es el mismo que el del historial: se marca aquí y aplica allí',
      (tester) async {
        movements.emit([
          buildMovement(
            id: 1,
            amount: 25000,
            date: daysAgo(1),
            description: 'Almuerzo',
          ),
          buildMovement(
            id: 2,
            amount: 8000,
            date: daysAgo(1),
            categoryId: 2,
            categoryName: 'Transporte',
            description: 'Bus',
          ),
        ]);
        await pumpApp(
          tester,
          movements: movements,
          categories: categories,
          tab: 'Histórico',
        );

        await tester.tap(find.byTooltip('Filtrar por categoría'));
        await tester.pumpAndSettle();
        await tester.tap(inFilterSheet('Transporte'));
        await tester.pumpAndSettle();
        await tester.tap(inFilterSheet('Ver 1 categoría'));
        await tester.pumpAndSettle();

        expect(find.byType(MovementTile), findsOneWidget);
        expect(find.text('Bus'), findsOneWidget);

        // Cambio de pestaña: el filtro acompaña, que es justo lo que se pidió.
        await tester.tap(find.text('Historial').last);
        await tester.pumpAndSettle();

        expect(find.byType(HistoryScreen), findsOneWidget);
        expect(find.text('1 categoría seleccionada'), findsOneWidget);
        expect(find.byType(MovementTile), findsOneWidget);
        expect(find.text('Bus'), findsOneWidget);
        expect(find.text('Almuerzo'), findsNothing);
      },
    );

    testWidgets('un filtro sin coincidencias en el rango lo explica', (
      tester,
    ) async {
      movements.emit([
        buildMovement(
          id: 1,
          amount: 25000,
          date: daysAgo(1),
          description: 'Almuerzo',
        ),
      ]);
      final container = await pumpApp(
        tester,
        movements: movements,
        categories: categories,
        tab: 'Histórico',
      );
      container.read(historyCategoryFilterProvider.notifier).toggle(2);
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(
        find.text(
          'No hay movimientos de las categorías elegidas en ese rango.',
        ),
        findsOneWidget,
      );
    });
  });
}
