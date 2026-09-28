import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/features/historical/providers/historical_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/providers/history_providers.dart';

import '../helpers/await_first_value.dart';
import '../helpers/fakes.dart';

/// Lógica de la pantalla de histórico: el rango de fechas y los totales.
/// Sin árbol de widgets, con `ProviderContainer` directo (ver S03).
ProviderContainer makeContainer(FakeMovementRepository repo) {
  final container = ProviderContainer(
    overrides: [movementRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  container.listen(rangeMovementsProvider, (_, _) {});
  return container;
}

void main() {
  group('HistoryRange', () {
    test('cuenta los días de ambos extremos', () {
      final range = HistoryRange(start: _day(10), end: _day(16));
      expect(range.days, 7);
    });

    test('un rango de un solo día vale 1', () {
      final range = HistoryRange(start: _day(5), end: _day(5));
      expect(range.days, 1);
    });

    test('exclusiveEnd es el día siguiente, porque el DAO es [start, end)', () {
      // Cruce de mes: `DateTime` lo normaliza solo, sin casos especiales.
      final range = HistoryRange(
        start: DateTime(2026, 2, 28),
        end: DateTime(2026, 2, 28),
      );
      expect(range.exclusiveEnd, DateTime(2026, 3, 1));
    });

    test('la igualdad mira día, mes y año, no la hora', () {
      final a = HistoryRange(start: _day(1), end: _day(5));
      final b = HistoryRange(
        start: DateTime(2026, 2, 1, 23, 59),
        end: DateTime(2026, 2, 5, 0, 1),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('defaultHistoryRange', () {
    test('son los últimos 90 días, terminado hoy', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final range = defaultHistoryRange();

      expect(range.end, today);
      expect(range.days, 90);
      expect(range.start, today.subtract(const Duration(days: 89)));
    });
  });

  group('historyRangeProvider', () {
    test('empieza en el rango por defecto', () {
      final container = makeContainer(FakeMovementRepository());

      expect(container.read(historyRangeProvider), defaultHistoryRange());
    });

    test('set() normaliza a medianoche y descarta la hora', () {
      final container = makeContainer(FakeMovementRepository());

      container
          .read(historyRangeProvider.notifier)
          .set(DateTime(2026, 1, 5, 18, 30), DateTime(2026, 2, 3, 7, 15));

      final range = container.read(historyRangeProvider);
      expect(range.start, DateTime(2026, 1, 5));
      expect(range.end, DateTime(2026, 2, 3));
    });

    test('set() invierte los extremos si llegan al revés', () {
      final container = makeContainer(FakeMovementRepository());

      container
          .read(historyRangeProvider.notifier)
          .set(DateTime(2026, 3, 10), DateTime(2026, 3, 1));

      final range = container.read(historyRangeProvider);
      expect(range.start, DateTime(2026, 3, 1));
      expect(range.end, DateTime(2026, 3, 10));
    });

    test('setStart() y setEnd() mueven un solo extremo', () {
      final container = makeContainer(FakeMovementRepository());
      final notifier = container.read(historyRangeProvider.notifier);
      final before = container.read(historyRangeProvider);

      notifier.setStart(DateTime(2026, 1, 1));
      expect(container.read(historyRangeProvider).end, before.end);

      notifier.setEnd(DateTime(2026, 1, 31));
      expect(container.read(historyRangeProvider).start, DateTime(2026, 1, 1));
    });

    test('setEnd() con una fecha anterior al inicio no rompe el rango', () {
      final container = makeContainer(FakeMovementRepository());
      final notifier = container.read(historyRangeProvider.notifier);
      notifier.set(DateTime(2026, 2, 10), DateTime(2026, 2, 20));

      notifier.setEnd(DateTime(2026, 2, 1));

      final range = container.read(historyRangeProvider);
      expect(range.start, DateTime(2026, 2, 1));
      expect(range.end, DateTime(2026, 2, 10));
    });

    test('reset() vuelve a los 90 días', () {
      final container = makeContainer(FakeMovementRepository());
      container
          .read(historyRangeProvider.notifier)
          .set(DateTime(2020, 1, 1), DateTime(2020, 1, 31));

      container.read(historyRangeProvider.notifier).reset();

      expect(container.read(historyRangeProvider), defaultHistoryRange());
    });
  });

  group('formatRange', () {
    test('los dos extremos en dd/mm/aaaa', () {
      final range = HistoryRange(start: _day(1), end: _day(28));
      expect(formatRange(range), '1/2/2026 – 28/2/2026');
    });
  });

  group('rangeMovementsProvider', () {
    test(
      'devuelve solo los movimientos del rango, incluidos los bordes',
      () async {
        final repo = FakeMovementRepository([
          buildMovement(id: 1, amount: 1000, date: DateTime(2026, 2, 1, 0, 0)),
          buildMovement(
            id: 2,
            amount: 2000,
            date: DateTime(2026, 2, 10, 23, 59),
          ),
          buildMovement(id: 3, amount: 3000, date: DateTime(2026, 2, 11, 0, 0)),
          buildMovement(id: 4, amount: 4000, date: DateTime(2026, 1, 31)),
        ]);
        final container = makeContainer(repo);
        container
            .read(historyRangeProvider.notifier)
            .set(DateTime(2026, 2, 1), DateTime(2026, 2, 10));

        final movements = await awaitFirstValue(
          () => container.read(rangeMovementsProvider),
          description: 'rangeMovementsProvider',
        );

        expect(movements.map((m) => m.id), [2, 1]);
      },
    );

    test(
      'aplica el filtro de categorías compartido con el historial',
      () async {
        final repo = FakeMovementRepository([
          buildMovement(id: 1, amount: 1000, date: DateTime(2026, 2, 2)),
          buildMovement(
            id: 2,
            amount: 2000,
            date: DateTime(2026, 2, 3),
            categoryId: 2,
            categoryName: 'Transporte',
          ),
        ]);
        final container = makeContainer(repo);
        container
            .read(historyRangeProvider.notifier)
            .set(DateTime(2026, 2, 1), DateTime(2026, 2, 28));
        container.read(historyCategoryFilterProvider.notifier).toggle(2);

        final movements = await awaitFirstValue(
          () => container.read(rangeMovementsProvider),
          description: 'rangeMovementsProvider filtrado',
        );

        expect(movements.map((m) => m.id), [2]);
      },
    );
  });

  group('rangeGroupsProvider y rangeTotalsProvider', () {
    test('agrupa por día y suma el balance de todo el rango', () async {
      final repo = FakeMovementRepository([
        buildMovement(id: 1, amount: 10000, date: DateTime(2026, 2, 1)),
        buildMovement(id: 2, amount: 5000, date: DateTime(2026, 2, 1)),
        buildMovement(
          id: 3,
          amount: 900000,
          date: DateTime(2026, 2, 5),
          type: MovementType.income,
        ),
      ]);
      final container = makeContainer(repo);
      container
          .read(historyRangeProvider.notifier)
          .set(DateTime(2026, 2, 1), DateTime(2026, 2, 28));

      final groups = await awaitFirstValue(
        () => container.read(rangeGroupsProvider),
        description: 'rangeGroupsProvider',
      );
      final totals = await awaitFirstValue(
        () => container.read(rangeTotalsProvider),
        description: 'rangeTotalsProvider',
      );

      expect(groups.map((g) => g.date.day), [5, 1]);
      expect(groups.first.net, 900000);
      expect(totals, (
        income: 900000,
        expense: 15000,
        balance: 885000,
      ), reason: 'el balance del rango descuenta los dos tipos');
    });

    test('cambiar el rango vuelve a pedir los movimientos', () async {
      final repo = FakeMovementRepository([
        buildMovement(id: 1, amount: 1000, date: DateTime(2026, 2, 1)),
        buildMovement(id: 2, amount: 2000, date: DateTime(2026, 4, 1)),
      ]);
      final container = makeContainer(repo);
      container
          .read(historyRangeProvider.notifier)
          .set(DateTime(2026, 2, 1), DateTime(2026, 2, 28));
      await awaitFirstValue(
        () => container.read(rangeMovementsProvider),
        description: 'primer rango',
      );

      container
          .read(historyRangeProvider.notifier)
          .set(DateTime(2026, 4, 1), DateTime(2026, 4, 30));

      // La condición mira *qué* movimiento llegó, no cuántos: con un
      // `length == 1` el valor viejo del primer rango también encajaría.
      final movements = await awaitValueWhere(
        () => container.read(rangeMovementsProvider),
        (list) => list.singleOrNull?.id == 2,
        description: 'el segundo rango',
      );
      expect(movements.map((m) => m.id), [2]);
    });
  });
}

/// Midnight on a fixed day, to keep the expected values readable.
DateTime _day(int day) => DateTime(2026, 2, day);
