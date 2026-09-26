import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/core/providers/router_provider.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/core/theme/theme_extensions.dart';
import 'package:pipefinanzaspersonales/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:pipefinanzaspersonales/features/dashboard/presentation/widgets/category_breakdown.dart';
import 'package:pipefinanzaspersonales/features/dashboard/presentation/widgets/last_month_card.dart';
import 'package:pipefinanzaspersonales/features/dashboard/presentation/widgets/month_selector.dart';
import 'package:pipefinanzaspersonales/features/dashboard/presentation/widgets/monthly_bars.dart';
import 'package:pipefinanzaspersonales/features/dashboard/presentation/widgets/totals_row.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_values.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/movement_tile.dart';

import '../helpers/fakes.dart';

/// El dashboard abre el formulario con `context.push`, así que necesita un
/// `GoRouter` real. Se sustituyen los dos repositorios: el de categorías lo
/// necesita el formulario al abrirse, y sin override construiría un
/// `AppDatabase` de verdad.
late FakeMovementRepository movements;
late FakeCategoryRepository categories;

/// **Por qué estos helpers existen:** el mismo importe sale en varios sitios.
/// Un gasto de 450.000 aparece en el balance, en la tarjeta de gastos, en la
/// fila del desglose y en la de movimientos recientes. Un `find.text('$450.000')`
/// a secas encuentra cuatro widgets y `tester.widget` revienta con
/// "Too many elements". Cada bloque se delimita por su propio widget.
Finder inBalance(String text) =>
    find.descendant(of: find.byType(BalanceCard), matching: find.text(text));

Finder inTotals(String text) =>
    find.descendant(of: find.byType(TotalsRow), matching: find.text(text));

Finder inBreakdown(String text) => find.descendant(
  of: find.byType(CategoryBreakdownList),
  matching: find.text(text),
);

Finder inLastMonth(String text) => find.descendant(
  of: find.byType(LastMonthCard),
  matching: find.text(text),
);

DateTime thisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openDashboard(WidgetTester tester) async {
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
}

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

  group('resumen del mes', () {
    testWidgets('muestra balance, ingresos y gastos', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 250000, date: DateTime(month.year, month.month, 3)),
        buildMovement(id: 2, amount: 60000, date: DateTime(month.year, month.month, 4)),
        buildMovement(
          id: 3,
          amount: 2000000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
        ),
      ]);
      await openDashboard(tester);

      expect(find.text('Balance · ${_monthName(month.month)} ${month.year}'), findsOneWidget);
      // Delimitado a las tarjetas: la leyenda del gráfico de 6 meses también
      // dice "Ingresos" y "Gastos".
      expect(inTotals('Ingresos'), findsOneWidget);
      expect(inTotals('Gastos'), findsOneWidget);
      // El subtotal de gastos aparece en su tarjeta, no solo en el balance.
      expect(inTotals('\$2.000.000'), findsOneWidget);
      expect(inTotals('\$310.000'), findsOneWidget);
    });

    testWidgets('el balance es verde cuando es positivo', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 900000,
          date: DateTime(month.year, month.month, 2),
          type: MovementType.income,
        ),
      ]);
      await openDashboard(tester);

      final balance = tester.widget<Text>(inBalance('+\$900.000'));
      final semantic = Theme.of(tester.element(find.byType(Text).first))
          .extension<SemanticColors>()!;
      expect(balance.style?.color, semantic.income);
    });

    testWidgets('el balance es rojo cuando es negativo', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 450000, date: DateTime(month.year, month.month, 2)),
      ]);
      await openDashboard(tester);

      final balance = tester.widget<Text>(inBalance('-\$450.000'));
      final semantic = Theme.of(tester.element(find.byType(Text).first))
          .extension<SemanticColors>()!;
      expect(balance.style?.color, semantic.expense);
    });

    testWidgets('con un solo movimiento el balance es ese monto', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 73500, date: DateTime(month.year, month.month, 9)),
      ]);
      await openDashboard(tester);

      expect(inBalance('-\$73.500'), findsOneWidget);
      expect(inTotals('\$73.500'), findsOneWidget);
    });

    testWidgets('muestra la tasa de ahorro cuando es calculable', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 1000000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
        ),
        buildMovement(id: 2, amount: 250000, date: DateTime(month.year, month.month, 2)),
      ]);
      await openDashboard(tester);

      expect(inBalance('Ahorro: 75.0% de tus ingresos'), findsOneWidget);
    });

    testWidgets('sin ingresos no inventa una tasa de ahorro', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 40000, date: DateTime(month.year, month.month, 2)),
      ]);
      await openDashboard(tester);

      expect(find.descendant(of: find.byType(BalanceCard), matching: find.textContaining('Ahorro:')), findsNothing);
    });
  });

  group('desglose por categoría', () {
    testWidgets('aparece ordenado de mayor a menor con su porcentaje', (
      tester,
    ) async {
      useTallScreen(tester);
      categories = FakeCategoryRepository([
        buildCategory(id: 1, name: 'Comida', iconKey: 'restaurant'),
        buildCategory(id: 2, name: 'Transporte', iconKey: 'directions_bus'),
        buildCategory(id: 3, name: 'Salario', type: MovementType.income, iconKey: 'work'),
      ]);
      movements.emit([
        buildMovement(id: 1, amount: 25000, date: DateTime(month.year, month.month, 1), categoryId: 1),
        buildMovement(id: 2, amount: 75000, date: DateTime(month.year, month.month, 1), categoryId: 2),
      ]);
      await openDashboard(tester);

      expect(find.text('Gastos por categoría'), findsOneWidget);
      expect(inBreakdown('\$75.000  75.0%'), findsOneWidget);
      expect(inBreakdown('\$25.000  25.0%'), findsOneWidget);

      // El orden de mayor a menor se comprueba por posición en el árbol,
      // delimitando al desglose: "Comida" también es el título de la fila del
      // movimiento reciente, así que el finder global encuentra tres.
      final transporte = tester.getTopLeft(inBreakdown('Transporte')).dy;
      final comida = tester.getTopLeft(inBreakdown('Comida')).dy;
      expect(transporte, lessThan(comida));
    });

    testWidgets('no aparece cuando el mes no tiene gastos', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 1500000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
        ),
      ]);
      await openDashboard(tester);

      expect(find.text('Gastos por categoría'), findsNothing);
    });
  });

  group('movimientos recientes', () {
    testWidgets('lista como máximo 5 y abre el editor', (tester) async {
      useTallScreen(tester);
      movements.emit([
        for (var i = 1; i <= 7; i++)
          buildMovement(
            id: i,
            amount: i * 1000,
            date: DateTime(month.year, month.month, i),
            description: 'Mov $i',
          ),
      ]);
      await openDashboard(tester);

      expect(find.text('Movimientos recientes'), findsOneWidget);
      expect(find.byType(MovementTile), findsNWidgets(5));

      await tester.tap(find.text('Mov 7'));
      await tester.pumpAndSettle();
      expect(find.text('Editar movimiento'), findsWidgets);
    });
  });

  group('selector de mes', () {
    testWidgets('‹ cambia los tres bloques a la vez', (tester) async {
      useTallScreen(tester);
      final previous = DateTime(month.year, month.month - 1);
      movements.emit([
        buildMovement(id: 1, amount: 100000, date: DateTime(month.year, month.month, 3)),
        buildMovement(id: 2, amount: 7000, date: DateTime(previous.year, previous.month, 3)),
      ]);
      await openDashboard(tester);
      expect(inBalance('-\$100.000'), findsOneWidget);

      await tester.tap(find.byTooltip('Mes anterior').first);
      await tester.pumpAndSettle();

      // Título del mes, balance y tarjeta de gastos.
      expect(
        find.text('Balance · ${_monthName(previous.month)} ${previous.year}'),
        findsOneWidget,
      );
      expect(inBalance('-\$7.000'), findsOneWidget);
      expect(inTotals('\$7.000'), findsOneWidget);
      expect(inBalance('-\$100.000'), findsNothing);
    });

    testWidgets('› está deshabilitado en el mes actual', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 3)),
      ]);
      await openDashboard(tester);

      final next = find.ancestor(
        of: find.byTooltip('Mes siguiente'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(next).onPressed, isNull);
    });

    testWidgets('el mes elegido se conserva al volver de Historial', (
      tester,
    ) async {
      useTallScreen(tester);
      final previous = DateTime(month.year, month.month - 1);
      movements.emit([
        buildMovement(id: 1, amount: 7000, date: DateTime(previous.year, previous.month, 3)),
      ]);
      await openDashboard(tester);

      // Se retrocede desde el historial, no desde el dashboard.
      await tester.tap(find.text('Historial').last);
      await tester.pumpAndSettle();
      // `hitTestable` y no `.first`: la rama del dashboard sigue montada en el
      // `StatefulShellRoute` aunque esté oculta, así que hay dos ‹ en el
      // árbol y `.first` sería el offstage.
      await tester.tap(find.byTooltip('Mes anterior').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(MovementTile), findsOneWidget, reason: 'el mes anterior sí tiene un gasto');

      await tester.tap(find.text('Inicio').last);
      await tester.pumpAndSettle();

      // Al cambiar de pestaña, `StatefulShellRoute` apaga el `TickerMode` de la
      // rama oculta y Riverpod reanuda sus suscripciones **durante el build**,
      // lo que produce un `setState() called during build`. Está registrado
      // en el plan (S06) y no rompe la UI, así que se consume aquí de forma
      // explícita y se comprueba que es *ese* diagnóstico y no otro: cualquier
      // excepción distinta haría fallar este `contains`.
      final diagnostic = tester.takeException();
      expect(
        diagnostic.toString(),
        contains('markNeedsBuild'),
        reason: 'solo se tolera el diagnóstico conocido de TickerMode',
      );

      expect(
        find.text('Balance · ${_monthName(previous.month)} ${previous.year}'),
        findsOneWidget,
      );
      expect(inBalance('-\$7.000'), findsOneWidget);
    });
  });

  group('gráfico de 6 meses', () {
    /// Las barras son los únicos `Tooltip` del gráfico (los valores de cero no
    /// lo llevan) y se localizan por **tamaño renderizado**, no por
    /// `Container.constraints`: `Container(width:, height:)` mete un
    /// `ConstrainedBox` interno y deja `constraints` en null.
    List<double> barHeights(WidgetTester tester) {
      return tester
          .widgetList<Tooltip>(
            find.descendant(
              of: find.byType(MonthlyBars),
              matching: find.byType(Tooltip),
            ),
          )
          .map((t) => tester.getSize(find.byWidget(t)).height)
          .toList(growable: false);
    }

    testWidgets('todas las barras comparten una escala', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 1000000, date: DateTime(month.year, month.month, 2)),
        buildMovement(id: 2, amount: 100000, date: DateTime(month.year, month.month - 1, 2)),
      ]);
      await openDashboard(tester);

      expect(find.text('Últimos 6 meses'), findsOneWidget);
      final heights = barHeights(tester);
      expect(heights, hasLength(2));
      // La mayor es la del mes con 1.000.000 y la otra es un décimo. Si cada
      // barra midiera contra su propio valor, las dos serían iguales.
      final tall = heights.reduce((a, b) => a > b ? a : b);
      final short = heights.reduce((a, b) => a < b ? a : b);
      expect(tall, greaterThan(100));
      expect(
        tall / short,
        closeTo(10, 0.5),
        reason: 'proporción 10:1 entre los importes',
      );
    });

    testWidgets('un valor muy pequeño se ve igual', (tester) async {
      useTallScreen(tester);
      // 1.000 contra 1.000.000 da un 0,1 %: sin el mínimo de 2 px esa barra
      // desaparecería y el mes parecería sin movimientos. Hace falta un
      // ingreso: las barras de valor cero no llevan `Tooltip`.
      movements.emit([
        buildMovement(
          id: 1,
          amount: 1000000,
          date: DateTime(month.year, month.month, 2),
          type: MovementType.income,
        ),
        buildMovement(id: 2, amount: 1000, date: DateTime(month.year, month.month, 2)),
      ]);
      await openDashboard(tester);

      final heights = barHeights(tester);
      expect(heights, hasLength(2));
      expect(
        heights.where((h) => h < 5),
        hasLength(1),
        reason: 'barra del gasto pequeño',
      );
      expect(heights.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(2));
    });

    testWidgets('las barras llevan el importe en el tooltip', (tester) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 250000, date: DateTime(month.year, month.month, 2)),
      ]);
      await openDashboard(tester);

      expect(
        find.descendant(
          of: find.byType(MonthlyBars),
          matching: find.byTooltip('\$250.000'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('se omite si la ventana entera está vacía', (tester) async {
      // Se monta el widget suelto. Desde el dashboard el mes visible sin
      // movimientos ya no es una excepción: la pantalla muestra el estado vacío
      // **y** el gráfico, que es justo el caso que comprueba este widget. La
      // guarda es para la ventana entera en cero, que sí puede llegar desde
      // una base recién creada.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MonthlyBars(
              bars: List.generate(
                6,
                (i) => MonthlyBar(month: DateTime(2026, i + 1), income: 0, expense: 0),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MonthlyBars), findsOneWidget);
      expect(find.text('Últimos 6 meses'), findsNothing);
    });
  });

  group('accesibilidad', () {
    testWidgets('el balance se anuncia con su signo, no solo con color', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 450000, date: DateTime(month.year, month.month, 2)),
      ]);
      await openDashboard(tester);

      final node = tester.getSemantics(find.byType(BalanceCard));
      expect(node.label, contains('Balance del mes'));
      expect(node.value, contains('Negativo'));
      expect(node.value, contains('-\$450.000'));
    });

    testWidgets('sin desbordes con la fuente a 1.3', (tester) async {
      useTallScreen(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      movements.emit([
        for (var i = 1; i <= 6; i++)
          buildMovement(
            id: i,
            amount: i * 12000,
            date: DateTime(month.year, month.month, i),
            categoryId: i.isEven ? 2 : 1,
            description: 'Movimiento con descripción larga $i',
          ),
        buildMovement(
          id: 7,
          amount: 1500000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
        ),
      ]);
      await openDashboard(tester);

      // Cualquier `RenderFlex overflowed` durante este pump habría marcado el
      // test como fallido; se comprueba además que no quedó ninguno pendiente.
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin desbordes con la fuente a 1.3 en el historial', (
      tester,
    ) async {
      useTallScreen(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      movements.emit([
        for (var i = 1; i <= 4; i++)
          buildMovement(
            id: i,
            amount: i * 90000,
            date: DateTime(month.year, month.month, i),
            description: 'Una descripción bastante larga para forzar el corte',
          ),
      ]);
      await openDashboard(tester);
      await tester.tap(find.text('Historial').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('estados', () {
    testWidgets('sin movimientos del mes aparece el estado vacío', (
      tester,
    ) async {
      useTallScreen(tester);
      await openDashboard(tester);

      expect(find.text('Este mes'), findsOneWidget);
      expect(
        find.textContaining('Aún no tienes movimientos'),
        findsOneWidget,
      );
    });

    testWidgets('un mes con gasto e ingreso del mismo valor no parece vacío', (
      tester,
    ) async {
      useTallScreen(tester);
      // Balance 0 pero con datos: si el estado vacío se decidiera por el
      // balance, esta pantalla mostraría "Aún no tienes movimientos".
      movements.emit([
        buildMovement(id: 1, amount: 50000, date: DateTime(month.year, month.month, 1)),
        buildMovement(
          id: 2,
          amount: 50000,
          date: DateTime(month.year, month.month, 2),
          type: MovementType.income,
        ),
      ]);
      await openDashboard(tester);

      expect(find.textContaining('Aún no tienes movimientos'), findsNothing);
      // `formatSigned(0)` da `+$0`: el cero es un balance, no un hueco.
      expect(inBalance('+\$0'), findsOneWidget);
      expect(inTotals('\$50.000'), findsNWidgets(2), reason: 'ingresos y gastos');
    });

    testWidgets('un fallo del repositorio muestra un mensaje de error', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 3)),
      ]);
      await openDashboard(tester);
      expect(inBalance('-\$1.000'), findsOneWidget);

      movements.emitError(StateError('fallo de base de datos'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo cargar el resumen'), findsOneWidget);
    });
  });

  /// El caso que reportó el usuario: se registra un movimiento del mes en
  /// curso, se llega a la pantalla de inicio viendo el mes anterior y esta
  /// muestra "Aún no tienes movimientos" con las flechas desaparecidas. Sin
  /// selector no había forma de volver al mes con los datos recién creados.
  group('mes sin movimientos', () {
    testWidgets('el selector sigue visible, con las dos flechas', (
      tester,
    ) async {
      useTallScreen(tester);
      await openDashboard(tester);

      expect(find.textContaining('Aún no tienes movimientos'), findsOneWidget);
      expect(find.byType(MonthSelector), findsOneWidget);
      expect(find.byTooltip('Mes anterior').hitTestable(), findsOneWidget);
      // Sin datos en ninguna parte el `›` está deshabilitado, pero presente:
      // en un mes pasado se habilita, y es el que faltaba.
      expect(find.byTooltip('Mes siguiente').hitTestable(), findsOneWidget);
    });

    testWidgets('el resumen del último mes con datos va debajo del mensaje', (
      tester,
    ) async {
      useTallScreen(tester);
      final previous = DateTime(month.year, month.month - 1);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 120000,
          date: DateTime(previous.year, previous.month, 5),
        ),
        buildMovement(
          id: 2,
          amount: 500000,
          date: DateTime(previous.year, previous.month, 6),
          type: MovementType.income,
        ),
      ]);
      await openDashboard(tester);

      expect(find.byType(LastMonthCard), findsOneWidget);
      expect(
        find.text('Resumen de ${_monthName(previous.month)} ${previous.year}'),
        findsOneWidget,
      );
      expect(inLastMonth('+\$380.000'), findsOneWidget);
      expect(
        inLastMonth(r'$500.000 de ingresos · $120.000 de gastos'),
        findsOneWidget,
      );

      // "Abajo" es parte del encargo: el resumen no puede quedar por encima
      // del mensaje, que es lo que el usuario ya estaba leyendo.
      final mensaje = tester.getTopLeft(
        find.textContaining('Aún no tienes movimientos'),
      );
      final resumen = tester.getTopLeft(find.byType(LastMonthCard));
      expect(mensaje.dy, lessThan(resumen.dy));
    });

    testWidgets('el resumen lleva a ese mes', (tester) async {
      useTallScreen(tester);
      final previous = DateTime(month.year, month.month - 1);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 90000,
          date: DateTime(previous.year, previous.month, 5),
        ),
      ]);
      await openDashboard(tester);

      await tester.tap(find.byType(LastMonthCard));
      await tester.pumpAndSettle();

      // Un toque al resumen sustituye el estado vacío por el panel de ese mes.
      expect(find.textContaining('Aún no tienes movimientos'), findsNothing);
      expect(
        find.text('Balance · ${_monthName(previous.month)} ${previous.year}'),
        findsOneWidget,
      );
      expect(inBalance('-\$90.000'), findsOneWidget);
    });

    testWidgets('el gráfico de 6 meses también se ve en el mes vacío', (
      tester,
    ) async {
      useTallScreen(tester);
      final previous = DateTime(month.year, month.month - 1);
      movements.emit([
        buildMovement(
          id: 1,
          amount: 400000,
          date: DateTime(previous.year, previous.month, 5),
        ),
      ]);
      await openDashboard(tester);

      expect(find.textContaining('Aún no tienes movimientos'), findsOneWidget);
      expect(find.text('Últimos 6 meses'), findsOneWidget);
    });

    testWidgets('"ver el mes actual" solo aparece fuera del mes en curso y vuelve', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([
        buildMovement(id: 1, amount: 80000, date: DateTime(month.year, month.month, 3)),
      ]);
      await openDashboard(tester);
      // El mes en curso tiene datos, así que no hay a dónde "volver".
      expect(find.text('Ver el mes actual'), findsNothing);

      await tester.tap(find.byTooltip('Mes anterior').hitTestable());
      await tester.pumpAndSettle();
      // Mes pasado vacío con el mes en curso lleno: el caso del usuario.
      expect(find.textContaining('Aún no tienes movimientos'), findsOneWidget);
      expect(find.text('Ver el mes actual'), findsOneWidget);
      // Y el mes anterior tampoco tiene datos de nada, así que no hay resumen
      // que ofrecer: la ventana de seis meses está vacía.
      expect(find.byType(LastMonthCard), findsNothing);

      await tester.tap(find.text('Ver el mes actual'));
      await tester.pumpAndSettle();

      expect(inBalance('-\$80.000'), findsOneWidget);
      expect(find.text('Ver el mes actual'), findsNothing);
    });

    testWidgets('sin datos en la ventana no hay resumen ni gráfico', (
      tester,
    ) async {
      useTallScreen(tester);
      await openDashboard(tester);

      expect(find.textContaining('Aún no tienes movimientos'), findsOneWidget);
      expect(find.byType(LastMonthCard), findsNothing);
      expect(find.text('Últimos 6 meses'), findsNothing);
      expect(find.text('Ver el mes actual'), findsNothing);
    });

    testWidgets('registrar un movimiento quita el estado vacío al volver', (
      tester,
    ) async {
      // El otro lado del reporte del usuario: se registró el movimiento y la
      // pantalla siguió en blanco. Aquí se recorre el camino entero, con el
      // router real y el FAB, para que el repintado por el stream del DAO
      // quede cubierto y no solo la escritura en el repositorio.
      useTallScreen(tester);
      await openDashboard(tester);
      expect(find.textContaining('Aún no tienes movimientos'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '0'), '25000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Vuelta en el dashboard: el panel del mes en curso, sin recargar.
      expect(find.textContaining('Aún no tienes movimientos'), findsNothing);
      expect(inBalance('-\$25.000'), findsOneWidget);
      expect(inTotals('\$25.000'), findsOneWidget);
    });
  });
}

String _monthName(int m) => const [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
][m - 1];
