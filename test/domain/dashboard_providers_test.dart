import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/features/categories/presentation/providers/category_providers.dart';
import 'package:pipefinanzaspersonales/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_summary.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_values.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/providers/history_providers.dart';

import '../helpers/await_first_value.dart';
import '../helpers/fakes.dart';

/// Lógica del resumen del mes. `ProviderContainer` directo, suscripción viva
/// y espera acotada (el patrón de S03, ampliado en S05 con `awaitValueWhere`).
ProviderContainer makeContainer(
  FakeMovementRepository movements,
  FakeCategoryRepository categories,
) {
  final container = ProviderContainer(
    overrides: [
      movementRepositoryProvider.overrideWithValue(movements),
      categoryRepositoryProvider.overrideWithValue(categories),
    ],
  );
  addTearDown(container.dispose);
  container.listen(movementsForSelectedMonthProvider, (_, _) {});
  container.listen(categoriesProvider, (_, _) {});
  return container;
}

DateTime thisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

void main() {
  final month = thisMonth();

  group('monthlySummaryProvider', () {
    test('suma ingresos, gastos y calcula el balance del mes', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 50000,
          date: DateTime(month.year, month.month, 2),
        ),
        buildMovement(
          id: 2,
          amount: 12000,
          date: DateTime(month.year, month.month, 3),
        ),
        buildMovement(
          id: 3,
          amount: 2000000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final s = await awaitFirstValue(
        () => container.read(monthlySummaryProvider),
        description: 'monthlySummaryProvider',
      );

      expect(s.totalExpense, 62000);
      expect(s.totalIncome, 2000000);
      expect(s.balance, 1938000);
      expect(s.transactionCount, 3);
    });

    test(
      'con exactamente un movimiento el balance es ese monto con su signo',
      () async {
        final movements = FakeMovementRepository([
          buildMovement(
            id: 1,
            amount: 73500,
            date: DateTime(month.year, month.month, 9),
          ),
        ]);
        final container = makeContainer(movements, FakeCategoryRepository());

        final s = await awaitFirstValue(
          () => container.read(monthlySummaryProvider),
        );

        // PRD: `balance = totalIncome - totalExpenses`. Un único gasto deja el
        // balance en negativo, no en el monto tal cual.
        expect(s.balance, -73500);
        expect(s.totalExpense, 73500);
        expect(s.totalIncome, 0);
        expect(s.transactionCount, 1);
      },
    );

    test('con un único ingreso el balance es positivo y exacto', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 73500,
          date: DateTime(month.year, month.month, 9),
          type: MovementType.income,
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final s = await awaitFirstValue(
        () => container.read(monthlySummaryProvider),
      );

      expect(s.balance, 73500);
      expect(s.totalIncome, 73500);
      expect(s.totalExpense, 0);
    });

    test('ignora los movimientos de otros meses', () async {
      final previous = DateTime(month.year, month.month - 1);
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 1000,
          date: DateTime(month.year, month.month, 5),
        ),
        buildMovement(
          id: 2,
          amount: 999999,
          date: DateTime(previous.year, previous.month, 5),
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final s = await awaitFirstValue(
        () => container.read(monthlySummaryProvider),
      );

      expect(s.totalExpense, 1000);
      expect(s.transactionCount, 1);
    });

    test('la tasa de ahorro es la fracción del ingreso que quedó', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 1000000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
        ),
        buildMovement(
          id: 2,
          amount: 250000,
          date: DateTime(month.year, month.month, 2),
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final s = await awaitFirstValue(
        () => container.read(monthlySummaryProvider),
      );

      expect(s.savingsRate, 75.0);
    });

    test('un mes sin ingresos no inventa una tasa de ahorro', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 30000,
          date: DateTime(month.year, month.month, 4),
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final s = await awaitFirstValue(
        () => container.read(monthlySummaryProvider),
      );

      expect(
        s.savingsRate,
        isNull,
        reason: 'dividir entre cero daría Infinity',
      );
      expect(s.balance, -30000);
    });
  });

  group('breakdownProvider', () {
    test('ordena de mayor a menor y los porcentajes suman 100', () async {
      final categories = FakeCategoryRepository([
        buildCategory(id: 1, name: 'Comida', iconKey: 'restaurant'),
        buildCategory(id: 2, name: 'Transporte', iconKey: 'directions_bus'),
        buildCategory(
          id: 3,
          name: 'Salario',
          type: MovementType.income,
          iconKey: 'work',
        ),
      ]);
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 5000,
          date: DateTime(month.year, month.month, 1),
          categoryId: 1,
        ),
        buildMovement(
          id: 2,
          amount: 30000,
          date: DateTime(month.year, month.month, 1),
          categoryId: 2,
        ),
        buildMovement(
          id: 3,
          amount: 20000,
          date: DateTime(month.year, month.month, 1),
          categoryId: 1,
        ),
        buildMovement(
          id: 4,
          amount: 900000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
          categoryId: 3,
        ),
      ]);
      final container = makeContainer(movements, categories);

      final items = await awaitFirstValue(
        () => container.read(breakdownProvider),
        description: 'breakdownProvider',
      );

      expect(items.map((b) => b.categoryName), ['Transporte', 'Comida']);
      expect(items.first.amount, 30000);
      expect(items.first.percentage, closeTo(54.5, 0.1));
      expect(items.last.amount, 25000, reason: 'los dos de comida se suman');
      expect(
        items.fold<double>(0, (acc, b) => acc + b.percentage),
        closeTo(100, 0.2),
      );
    });

    test('no incluye ingresos en el desglose de gastos', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 1000000,
          date: DateTime(month.year, month.month, 1),
          type: MovementType.income,
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final items = await awaitFirstValue(
        () => container.read(breakdownProvider),
      );

      expect(items, isEmpty);
    });

    test('un mes sin gastos tampoco muestra desglose', () async {
      final movements = FakeMovementRepository();
      final container = makeContainer(movements, FakeCategoryRepository());

      final items = await awaitFirstValue(
        () => container.read(breakdownProvider),
      );

      expect(items, isEmpty);
    });
  });

  group('recentMovementsProvider', () {
    test('devuelve como máximo 5, en el orden del DAO', () async {
      final movements = FakeMovementRepository([
        for (var i = 1; i <= 8; i++)
          buildMovement(
            id: i,
            amount: i * 1000,
            date: DateTime(month.year, month.month, i),
          ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final list = await awaitFirstValue(
        () => container.read(recentMovementsProvider),
        description: 'recentMovementsProvider',
      );

      expect(list, hasLength(5));
      // El DAO entrega date DESC, así que los 5 primeros son los más recientes.
      expect(list.map((m) => m.id), [8, 7, 6, 5, 4]);
    });

    test('con menos de 5 devuelve todos', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 1000,
          date: DateTime(month.year, month.month, 1),
        ),
        buildMovement(
          id: 2,
          amount: 2000,
          date: DateTime(month.year, month.month, 2),
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());

      final list = await awaitFirstValue(
        () => container.read(recentMovementsProvider),
      );

      expect(list, hasLength(2));
    });
  });

  test('el dashboard y el historial comparten el mes seleccionado', () async {
    final movements = FakeMovementRepository([
      buildMovement(
        id: 1,
        amount: 50000,
        date: DateTime(month.year, month.month, 2),
      ),
      buildMovement(
        id: 2,
        amount: 10000,
        date: DateTime(month.year, month.month - 1, 2),
      ),
    ]);
    final container = makeContainer(movements, FakeCategoryRepository());
    final current = await awaitFirstValue(
      () => container.read(monthlySummaryProvider),
    );
    expect(current.totalExpense, 50000);

    // Se cambia el mes por el mismo provider que mueve el historial.
    container.read(selectedMonthProvider.notifier).previous();

    final previous = await awaitValueWhere<FinancialSummary>(
      () => container.read(monthlySummaryProvider),
      (s) => s.totalExpense == 10000,
      description: 'el resumen del mes anterior',
    );
    expect(previous.totalExpense, 10000);
    expect(
      container.read(selectedMonthProvider),
      DateTime(month.year, month.month - 1),
    );
  });

  test('una nueva emisión recalcula el resumen', () async {
    final movements = FakeMovementRepository([
      buildMovement(
        id: 1,
        amount: 1000,
        date: DateTime(month.year, month.month, 5),
      ),
    ]);
    final container = makeContainer(movements, FakeCategoryRepository());
    await awaitFirstValue(() => container.read(monthlySummaryProvider));

    movements.emit([
      buildMovement(
        id: 1,
        amount: 1000,
        date: DateTime(month.year, month.month, 5),
      ),
      buildMovement(
        id: 2,
        amount: 2000,
        date: DateTime(month.year, month.month, 6),
      ),
    ]);

    final s = await awaitValueWhere<FinancialSummary>(
      () => container.read(monthlySummaryProvider),
      (v) => v.transactionCount == 2,
      description: 'el resumen tras emitir',
    );
    expect(s.totalExpense, 3000);
  });

  group('lastSixMonthsProvider', () {
    test('devuelve 6 meses terminando en el mes seleccionado', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 50000,
          date: DateTime(month.year, month.month, 3),
        ),
        buildMovement(
          id: 2,
          amount: 900000,
          date: DateTime(month.year, month.month - 2, 10),
          type: MovementType.income,
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());
      container.listen(allMovementsProvider, (_, _) {});

      final bars = await awaitFirstValue(
        () => container.read(lastSixMonthsProvider),
        description: 'lastSixMonthsProvider',
      );

      expect(bars, hasLength(6));
      expect(
        bars.last.month,
        month,
        reason: 'la ventana termina en el mes elegido',
      );
      expect(bars[3].month, DateTime(month.year, month.month - 2));
      expect(bars[3].income, 900000);
      expect(bars.last.expense, 50000);
      // Un mes sin movimientos debe venir con ceros, no desaparecer: si no,
      // el gráfico saltaría de un mes con datos al siguiente.
      expect(bars.first.income, 0);
      expect(bars.first.expense, 0);
    });

    test('la ventana se mueve con el filtro mensual', () async {
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 50000,
          date: DateTime(month.year, month.month, 3),
        ),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());
      container.listen(allMovementsProvider, (_, _) {});
      final now = await awaitFirstValue(
        () => container.read(lastSixMonthsProvider),
      );
      expect(now.last.month, month);

      container.read(selectedMonthProvider.notifier).previous();

      final previous = await awaitValueWhere(
        () => container.read(lastSixMonthsProvider),
        (b) => b.last.month != month,
        description: 'el gráfico del mes anterior',
      );
      expect(previous.last.month, DateTime(month.year, month.month - 1));
    });

    test('incluye movimientos de meses anteriores al filtro', () async {
      // El gráfico es de 6 meses: leer solo el mes visible lo dejaría vacío.
      final old = DateTime(month.year, month.month - 4, 5);
      final movements = FakeMovementRepository([
        buildMovement(
          id: 1,
          amount: 50000,
          date: DateTime(month.year, month.month, 3),
        ),
        buildMovement(id: 2, amount: 777000, date: old),
      ]);
      final container = makeContainer(movements, FakeCategoryRepository());
      container.listen(allMovementsProvider, (_, _) {});

      final bars = await awaitFirstValue(
        () => container.read(lastSixMonthsProvider),
      );

      expect(bars[1].expense, 777000);
    });
  });

  group('lastMonthWithDataProvider', () {
    test(
      'devuelve el mes más reciente con movimientos, no el más antiguo',
      () async {
        final movements = FakeMovementRepository([
          buildMovement(
            id: 1,
            amount: 7000,
            date: DateTime(month.year, month.month - 4, 5),
          ),
          buildMovement(
            id: 2,
            amount: 40000,
            date: DateTime(month.year, month.month - 1, 8),
          ),
          buildMovement(
            id: 3,
            amount: 900000,
            date: DateTime(month.year, month.month - 1, 9),
            type: MovementType.income,
          ),
        ]);
        final container = makeContainer(movements, FakeCategoryRepository());
        container.listen(allMovementsProvider, (_, _) {});

        final bar = await awaitFirstValue(
          () => container.read(lastMonthWithDataProvider),
          description: 'lastMonthWithDataProvider',
        );

        expect(bar, isNotNull);
        expect(bar!.month, DateTime(month.year, month.month - 1));
        expect(bar.income, 900000);
        expect(bar.expense, 40000);
      },
    );

    test('devuelve null si en la ventana no se registró nada', () async {
      final container = makeContainer(
        FakeMovementRepository(),
        FakeCategoryRepository(),
      );
      container.listen(allMovementsProvider, (_, _) {});

      final bar = await awaitFirstValue(
        () => container.read(lastMonthWithDataProvider),
        description: 'lastMonthWithDataProvider',
      );

      // No hay nada que resumir: inventar un mes en cero dejaría una tarjeta
      // con un balance de $0 que parece un mes real sin actividad.
      expect(bar, isNull);
    });

    test(
      'la ventana va con el filtro: un mes que se sale no se ofrece',
      () async {
        // El único movimiento está a cinco meses. Con el filtro en el mes actual
        // entra en la ventana de seis; al retroceder seis meses, la ventana ya
        // no lo alcanza y no hay nada que ofrecer.
        final movements = FakeMovementRepository([
          buildMovement(
            id: 1,
            amount: 50000,
            date: DateTime(month.year, month.month - 5, 3),
          ),
        ]);
        final container = makeContainer(movements, FakeCategoryRepository());
        container.listen(allMovementsProvider, (_, _) {});

        final cerca = await awaitFirstValue(
          () => container.read(lastMonthWithDataProvider),
          description: 'lastMonthWithDataProvider',
        );
        expect(cerca?.month, DateTime(month.year, month.month - 5));

        final notifier = container.read(selectedMonthProvider.notifier);
        for (var i = 0; i < 6; i++) {
          notifier.previous();
        }

        final lejos = await awaitValueWhere<MonthlyBar?>(
          () => container.read(lastMonthWithDataProvider),
          (v) => v == null,
          description: 'lastMonthWithDataProvider sin el mes en ventana',
        );
        expect(lejos, isNull);
      },
    );
  });

  test('el desglose hereda el error del resumen', () async {
    final movements = FakeMovementRepository();
    final container = makeContainer(movements, FakeCategoryRepository());
    await awaitFirstValue(() => container.read(monthlySummaryProvider));

    movements.emitError(StateError('fallo'));

    // `awaitValueWhere` lanza el error en vez de devolverlo, así que aquí se
    // sondea el `AsyncValue` directamente hasta que marque fallo.
    for (
      var i = 0;
      i < 100 && !container.read(breakdownProvider).hasError;
      i++
    ) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(container.read(breakdownProvider).hasError, isTrue);
    expect(container.read(breakdownProvider).error, isA<StateError>());
  });
}
