import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_values.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/providers/history_providers.dart';

import '../helpers/await_first_value.dart';
import '../helpers/fakes.dart';

/// Lógica del filtro mensual y del agrupado por día. Sin árbol de widgets:
/// `ProviderContainer` directo, suscripción viva y espera acotada (ver S03).
ProviderContainer makeContainer(FakeMovementRepository repo) {
  final container = ProviderContainer(
    overrides: [movementRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  container.listen(movementsForSelectedMonthProvider, (_, _) {});
  return container;
}

DateTime thisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

void main() {
  final month = thisMonth();

  group('agrupado por día', () {
    test('los días salen del más reciente al más antiguo', () async {
      final repo = FakeMovementRepository([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 3)),
        buildMovement(id: 2, amount: 2000, date: DateTime(month.year, month.month, 20)),
        buildMovement(id: 3, amount: 3000, date: DateTime(month.year, month.month, 11)),
      ]);
      final container = makeContainer(repo);

      final groups = await awaitFirstValue(
        () => container.read(historyGroupsProvider),
        description: 'historyGroupsProvider',
      );

      expect(
        groups.map((g) => g.date.day),
        [20, 11, 3],
        reason: 'el DAO ordena date DESC y el agrupado no debe reordenar',
      );
    });

    test('cada día lleva sus subtotales de ingreso y gasto', () async {
      final repo = FakeMovementRepository([
        buildMovement(id: 1, amount: 5000, date: DateTime(month.year, month.month, 7)),
        buildMovement(id: 2, amount: 1200, date: DateTime(month.year, month.month, 7)),
        buildMovement(
          id: 3,
          amount: 900000,
          date: DateTime(month.year, month.month, 7),
          type: MovementType.income,
        ),
      ]);
      final container = makeContainer(repo);

      final groups = await awaitFirstValue(
        () => container.read(historyGroupsProvider),
      );

      expect(groups, hasLength(1));
      expect(groups.single.totalExpense, 6200);
      expect(groups.single.totalIncome, 900000);
      expect(groups.single.movements, hasLength(3));
    });

    test('dentro de un día el orden también es el más reciente primero', () async {
      final repo = FakeMovementRepository([
        buildMovement(id: 1, amount: 100, date: DateTime(month.year, month.month, 7, 9)),
        buildMovement(id: 2, amount: 200, date: DateTime(month.year, month.month, 7, 18)),
      ]);
      final container = makeContainer(repo);

      final groups = await awaitFirstValue(
        () => container.read(historyGroupsProvider),
      );

      expect(groups.single.movements.map((m) => m.id), [2, 1]);
    });

    test('el filtro descarta los movimientos de otros meses', () async {
      final previous = DateTime(month.year, month.month - 1);
      final repo = FakeMovementRepository([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 5)),
        buildMovement(id: 2, amount: 9999, date: DateTime(previous.year, previous.month, 5)),
      ]);
      final container = makeContainer(repo);

      final groups = await awaitFirstValue(
        () => container.read(historyGroupsProvider),
      );

      expect(groups, hasLength(1));
      expect(groups.single.totalExpense, 1000, reason: 'no debe filtrar el mes anterior');
    });

    test('una nueva emisión del repositorio reagrupa sin recrear el provider', () async {
      final repo = FakeMovementRepository([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 5)),
      ]);
      final container = makeContainer(repo);
      await awaitFirstValue(() => container.read(historyGroupsProvider));

      repo.emit([
        buildMovement(id: 1, amount: 1000, date: DateTime(month.year, month.month, 5)),
        buildMovement(id: 2, amount: 2000, date: DateTime(month.year, month.month, 8)),
      ]);

      final groups = await awaitValueWhere<List<DailyGroup>>(
        () => container.read(historyGroupsProvider),
        (g) => g.length == 2,
        description: 'la actualización tras emitir',
      );
      expect(groups.map((g) => g.date.day), [8, 5]);
    });
  });

  group('selectedMonthProvider', () {
    test('empieza en el mes en curso, con el día a 1', () {
      final container = makeContainer(FakeMovementRepository());

      expect(container.read(selectedMonthProvider), month);
    });

    test('previous() retrocede un mes y cruza el año sin casos especiales', () {
      final container = makeContainer(FakeMovementRepository());
      container.read(selectedMonthProvider.notifier).goTo(DateTime(2026, 1));

      container.read(selectedMonthProvider.notifier).previous();

      expect(container.read(selectedMonthProvider), DateTime(2025, 12));
    });

    test('next() no avanza más allá del mes en curso', () {
      final container = makeContainer(FakeMovementRepository());

      container.read(selectedMonthProvider.notifier).next();

      expect(container.read(selectedMonthProvider), month);
    });

    test('goTo() descarta el día: el filtro es por mes', () {
      final container = makeContainer(FakeMovementRepository());

      container.read(selectedMonthProvider.notifier).goTo(DateTime(2026, 5, 17));

      expect(container.read(selectedMonthProvider), DateTime(2026, 5));
    });
  });

  group('canAdvanceMonthProvider', () {
    test('es false en el mes en curso', () {
      final container = makeContainer(FakeMovementRepository());

      expect(container.read(canAdvanceMonthProvider), isFalse);
    });

    test('es true en un mes anterior y vuelve a false al volver al actual', () {
      final container = makeContainer(FakeMovementRepository());
      final notifier = container.read(selectedMonthProvider.notifier);

      notifier.previous();
      expect(container.read(canAdvanceMonthProvider), isTrue);

      notifier.next();
      expect(container.read(canAdvanceMonthProvider), isFalse);
    });
  });
}
