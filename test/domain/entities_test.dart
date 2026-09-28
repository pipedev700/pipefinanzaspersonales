import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_values.dart';

import '../helpers/fakes.dart';

/// S08 — Igualdad, `copyWith` y los valores derivados de `Movement`.
///
/// `Movement.==` compara **solo por `id`**, y eso no es un detalle: es lo
/// que hace que Riverpod no reconstruya la pantalla cuando un stream de Drift
/// reemite objetos nuevos pero idénticos. Si alguien "corrige" el `==` para
/// comparar todos los campos, la app sigue funcionando pero cada escritura
/// reconstruye el dashboard entero. Estos tests fijan el criterio.
void main() {
  group('identidad por id', () {
    test(
      'dos movimientos con el mismo id son iguales aunque todo lo demás no',
      () {
        final a = buildMovement(
          id: 7,
          amount: 1000,
          date: DateTime(2026, 1, 10),
          description: 'uno',
        );
        final b = buildMovement(
          id: 7,
          amount: 999999,
          date: DateTime(2025, 6, 1),
          description: 'otro',
          type: MovementType.income,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      },
    );

    test('movimientos con distinto id no son iguales', () {
      final a = buildMovement(id: 1, amount: 1000, date: DateTime(2026, 1, 10));
      final b = buildMovement(id: 2, amount: 1000, date: DateTime(2026, 1, 10));

      expect(a, isNot(b));
    });

    test('un movimiento sin persistir (id 0) no colapsa con otro id 0', () {
      // Riesgo real del criterio "solo id": dos movimientos nuevos valen
      // ambos 0. Se acepta la limitación — la app no compara listas de
      // borradores — pero queda escrito para que no sorprenda.
      final a = buildMovement(id: 0, amount: 1000, date: DateTime(2026, 1, 10));
      final b = buildMovement(id: 0, amount: 2000, date: DateTime(2026, 1, 11));

      expect(a, b, reason: 'limitación conocida del criterio por id');
    });

    test('no es igual a un objeto de otro tipo', () {
      final a = buildMovement(id: 1, amount: 1000, date: DateTime(2026, 1, 10));
      expect(a == Object(), isFalse);
    });
  });

  group('Category: identidad por id', () {
    test('misma id es igualdad aunque cambie el resto', () {
      final a = buildCategory(id: 4, name: 'Comida');
      final b = buildCategory(
        id: 4,
        name: 'Renombrada',
        type: MovementType.income,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('distinta id no es igualdad', () {
      expect(buildCategory(id: 4), isNot(buildCategory(id: 5)));
    });

    test('no es igual a un objeto de otro tipo', () {
      expect(buildCategory(id: 4) == Object(), isFalse);
    });
  });

  group('copyWith', () {
    final original = buildMovement(
      id: 3,
      amount: 25000,
      date: DateTime(2026, 1, 10),
      description: 'almuerzo',
    );

    test('sin argumentos devuelve un movimiento equivalente', () {
      final copy = original.copyWith();

      expect(copy, original);
      expect(copy.amount, original.amount);
      expect(copy.date, original.date);
      expect(copy.description, original.description);
      expect(copy.category.id, original.category.id);
    });

    test('cambia solo lo indicado y conserva el resto', () {
      final copy = original.copyWith(amount: 30000, description: 'cena');

      expect(copy.amount, 30000);
      expect(copy.description, 'cena');
      expect(copy.date, original.date, reason: 'la fecha no se toca');
      expect(copy.type, original.type);
      expect(copy.category, original.category);
    });

    test('nunca cambia el id ni el createdAt', () {
      // El id es la identidad y `createdAt` es la marca de creación: los
      // dos se fijan al insertar. `copyWith` no ofrece la opción de
      // tocarlos, y este test lo vigila.
      final copy = original.copyWith(
        amount: 1,
        type: MovementType.income,
        category: buildCategory(id: 99, name: 'Otro'),
        date: DateTime(2020, 1, 1),
        description: 'x',
        updatedAt: DateTime(2030, 1, 1),
      );

      expect(copy.id, original.id);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, DateTime(2030, 1, 1), reason: 'sí se puede mover');
    });

    test('el original no se muta', () {
      original.copyWith(amount: 1);
      expect(original.amount, 25000);
    });
  });

  group('valores derivados', () {
    test('signedAmount aplica el signo del tipo, no del monto', () {
      final gasto = buildMovement(
        id: 1,
        amount: 50000,
        date: DateTime(2026, 1, 10),
        type: MovementType.expense,
      );
      final ingreso = buildMovement(
        id: 2,
        amount: 50000,
        date: DateTime(2026, 1, 10),
        type: MovementType.income,
      );

      expect(gasto.signedAmount, -50000);
      expect(ingreso.signedAmount, 50000);
    });

    test('isIncome delega en el tipo', () {
      expect(
        buildMovement(
          id: 1,
          amount: 1,
          date: DateTime(2026, 1, 1),
          type: MovementType.income,
        ).isIncome,
        isTrue,
      );
      expect(
        buildMovement(
          id: 2,
          amount: 1,
          date: DateTime(2026, 1, 1),
          type: MovementType.expense,
        ).isIncome,
        isFalse,
      );
    });
  });

  group('MovementType', () {
    test('sign coincide con el criterio §7', () {
      expect(MovementType.income.sign, 1);
      expect(MovementType.expense.sign, -1);
    });

    test('isIncome e isExpense son complementarios', () {
      for (final type in MovementType.values) {
        expect(type.isIncome, isNot(type.isExpense), reason: '$type');
      }
    });

    test('label rotula en español', () {
      expect(MovementType.income.label, 'Ingreso');
      expect(MovementType.expense.label, 'Gasto');
    });
  });

  group('CategoryBreakdown', () {
    test('guarda los datos del desglose sin recalcular nada', () {
      const b = CategoryBreakdown(
        categoryId: 1,
        categoryName: 'Comida',
        colorValue: 0xFFF97316,
        iconKey: 'restaurant',
        amount: 30000,
        percentage: 75,
      );

      expect(b.categoryName, 'Comida');
      expect(b.amount, 30000);
      expect(b.percentage, 75);
    });
  });

  group('MonthlyBar', () {
    test('max es el mayor de los dos importes', () {
      final gasto = MonthlyBar(month: _enero, income: 100, expense: 900);
      final ingreso = MonthlyBar(month: _enero, income: 900, expense: 100);
      final cero = MonthlyBar(month: _enero, income: 0, expense: 0);

      expect(gasto.max, 900);
      expect(ingreso.max, 900);
      expect(cero.max, 0, reason: 'un mes vacío no escala a NaN');
    });

    test('el mes es solo la etiqueta, no participa en el máximo', () {
      final a = MonthlyBar(month: _enero, income: 1, expense: 2);
      final b = MonthlyBar(month: _febrero, income: 1, expense: 2);

      expect(a.max, b.max);
    });
  });
}

final _enero = DateTime(2026, 1);
final _febrero = DateTime(2026, 2);
