import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/category.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_calculator.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_summary.dart';

const calc = FinancialCalculator();

/// `id` 0 = no persistido. Cada helper usa un id distinto para que las
/// comparaciones por identidad de `Movement` no se confundan.
var _nextId = 0;

Category category(int id, String name) => Category(
  id: id,
  name: name,
  colorValue: 0xFF000000,
  iconKey: 'home',
  type: MovementType.expense,
  isDefault: true,
  sortOrder: 0,
);

const comida = 1;
const transporte = 2;
const ocio = 3;

Movement expense(
  int amount, {
  int categoryId = comida,
  int day = 15,
  int month = 3,
}) => Movement(
  id: _nextId++,
  amount: amount,
  type: MovementType.expense,
  category: category(categoryId, 'cat$categoryId'),
  date: DateTime(2026, month, day),
  description: 'gasto',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Movement income(int amount, {int day = 1, int month = 3}) => Movement(
  id: _nextId++,
  amount: amount,
  type: MovementType.income,
  category: category(100, 'Ingreso'),
  date: DateTime(2026, month, day),
  description: 'sueldo',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('totales', () {
    test('suma ingresos y gastos por separado', () {
      final list = [income(3000000), expense(25000), expense(80000)];
      expect(calc.totalIncome(list), 3000000);
      expect(calc.totalExpense(list), 105000);
    });

    test('el balance descuenta los gastos', () {
      final list = [income(3000000), expense(25000), expense(80000)];
      expect(calc.balance(list), 2895000);
    });

    test('el balance puede ser negativo', () {
      final list = [income(100000), expense(250000)];
      expect(calc.balance(list), -150000);
    });

    test('lista vacía da ceros y no lanza', () {
      expect(calc.totalIncome([]), 0);
      expect(calc.totalExpense([]), 0);
      expect(calc.balance([]), 0);
    });

    test('ignora el signo del monto y usa el tipo', () {
      // Un gasto guardado como positivo resta igual.
      expect(calc.balance([expense(500)]), -500);
    });
  });

  group('desglose por categoría', () {
    final categories = [
      category(1, 'Comida'),
      category(2, 'Transporte'),
      category(3, 'Ocio'),
    ];

    test('ordena de mayor a menor y calcula porcentajes', () {
      final list = [
        expense(60000, categoryId: 1),
        expense(30000, categoryId: 2),
        expense(10000, categoryId: 3),
      ];
      final breakdown = calc.breakdownByCategory(list, categories);

      expect(breakdown.length, 3);
      expect(breakdown.first.categoryName, 'Comida');
      expect(breakdown.first.amount, 60000);
      expect(breakdown.first.percentage, 60.0);
      expect(breakdown[1].percentage, 30.0);
      expect(breakdown.last.percentage, 10.0);
      // Los porcentajes suman 100.
      expect(
        breakdown.fold<double>(0, (s, b) => s + b.percentage).round(),
        100,
      );
    });

    test('agrupa varios gastos de la misma categoría', () {
      final list = [
        expense(30000, categoryId: 1),
        expense(20000, categoryId: 1),
        expense(50000, categoryId: 2),
      ];
      final breakdown = calc.breakdownByCategory(list, categories);

      expect(breakdown.length, 2);
      expect(breakdown.first.amount, 50000);
      expect(breakdown.first.percentage, 50.0);
      expect(breakdown.last.amount, 50000);
    });

    test('los ingresos no aparecen en el desglose', () {
      final breakdown = calc.breakdownByCategory([
        income(3000000),
        expense(25000, categoryId: 1),
      ], categories);
      expect(breakdown.length, 1);
      expect(breakdown.single.amount, 25000);
    });

    test('sin gastos devuelve lista vacía', () {
      expect(calc.breakdownByCategory([income(100)], categories), isEmpty);
    });

    test('una categoría borrada no rompe el desglose', () {
      final list = [expense(10000, categoryId: 999)];
      final breakdown = calc.breakdownByCategory(list, categories);
      expect(breakdown.single.categoryName, 'Sin categoría');
      expect(breakdown.single.percentage, 100.0);
    });
  });

  group('agrupación por día', () {
    test('conserva el orden y calcula los subtotales del día', () {
      final list = [
        income(3000000, day: 1),
        expense(25000, day: 1),
        expense(80000, day: 2),
        expense(5000, day: 2),
      ];
      final groups = calc.groupByDay(list);

      expect(groups.length, 2);
      expect(groups.first.date, DateTime(2026, 3, 1));
      expect(groups.first.movements.length, 2);
      expect(groups.first.totalIncome, 3000000);
      expect(groups.first.totalExpense, 25000);
      expect(groups.last.totalExpense, 85000);
    });

    test('un movimiento de medianoche agrupa con los de ese día', () {
      final list = [
        expense(1000, day: 10),
        expense(2000).copyWith(date: DateTime(2026, 3, 10, 23, 59)),
      ];
      final groups = calc.groupByDay(list);
      expect(groups.length, 1);
      expect(groups.single.movements.length, 2);
    });

    // El defecto que motivó `DailyGroup.net`: la cabecera pintaba solo el gasto
    // con un "-" delante, así que un día con sueldo se veía en rojo.
    test('net resta los gastos al ingreso del día', () {
      final groups = calc.groupByDay([
        income(3000000, day: 1),
        expense(100000, day: 1),
      ]);

      expect(groups.single.net, 2900000);
      expect(groups.single.isPositive, isTrue);
    });

    test('un día solo de gastos tiene net negativo', () {
      final groups = calc.groupByDay([expense(85000, day: 2)]);

      expect(groups.single.net, -85000);
      expect(groups.single.isPositive, isFalse);
    });

    test('un día que empata se cuenta como positivo, no como pérdida', () {
      final groups = calc.groupByDay([
        income(50000, day: 3),
        expense(50000, day: 3),
      ]);

      expect(groups.single.net, 0);
      expect(
        groups.single.isPositive,
        isTrue,
        reason: 'no ganó ni perdió; pintarlo en rojo sugeriría una pérdida',
      );
    });
  });

  group('promedio mensual', () {
    test('promedia solo sobre los meses con gastos', () {
      final list = [
        expense(60000, month: 1),
        expense(40000, month: 1),
        expense(100000, month: 2),
      ];
      // Enero 100.000, febrero 100.000 -> 100.000
      expect(calc.monthlyAverage(list, 6), 100000);
    });

    test('un mes sin gastos no baja el promedio', () {
      final list = [expense(100000, month: 1), expense(300000, month: 3)];
      // Solo enero y marzo cuentan: (100.000 + 300.000) / 2
      expect(calc.monthlyAverage(list, 6), 200000);
    });

    test('ignora los ingresos al promediar', () {
      final list = [income(9000000, month: 1), expense(50000, month: 1)];
      expect(calc.monthlyAverage(list, 6), 50000);
    });

    test('sin datos o count inválido devuelve cero', () {
      expect(calc.monthlyAverage([], 6), 0);
      expect(calc.monthlyAverage([expense(100)], 0), 0);
    });
  });

  group('últimos meses', () {
    test('devuelve los meses pedidos, de más antiguo a más reciente', () {
      final bars = calc.lastMonths([], 6, DateTime(2026, 3, 15));
      expect(bars.length, 6);
      expect(bars.first.month, DateTime(2025, 10));
      expect(bars.last.month, DateTime(2026, 3));
    });

    test('asigna cada movimiento a su mes', () {
      final list = [income(3000000, month: 3), expense(50000, month: 1)];
      final bars = calc.lastMonths(list, 6, DateTime(2026, 3, 15));

      // Ventana: oct-25, nov-25, dic-25, ene-26, feb-26, mar-26.
      expect(bars.last.month, DateTime(2026, 3));
      expect(bars.last.income, 3000000);
      expect(bars.last.expense, 0);
      expect(bars[3].month, DateTime(2026, 1));
      expect(bars[3].expense, 50000);
      expect(bars.first.month, DateTime(2025, 10));
      expect(bars.first.income, 0);
    });

    test('cruza la frontera de año', () {
      final bars = calc.lastMonths([], 3, DateTime(2026, 1, 10));
      expect(bars.map((b) => b.month.month).toList(), [11, 12, 1]);
      expect(bars.first.month.year, 2025);
    });
  });

  group('FinancialSummary', () {
    test('deriva todos los totales y el desglose', () {
      final summary = FinancialSummary.from(
        [income(3000000), expense(100000, categoryId: 1)],
        [category(1, 'Comida')],
      );

      expect(summary.totalIncome, 3000000);
      expect(summary.totalExpense, 100000);
      expect(summary.balance, 2900000);
      expect(summary.transactionCount, 2);
      expect(summary.byCategory.single.categoryName, 'Comida');
    });

    test('tasa de ahorro redondeada a un decimal', () {
      expect(
        const FinancialSummary(
          totalIncome: 3000000,
          totalExpense: 2500000,
          balance: 500000,
          transactionCount: 2,
          byCategory: [],
        ).savingsRate,
        16.7,
      );
    });

    test('tasa de ahorro es null sin ingresos, no Infinity', () {
      expect(
        const FinancialSummary(
          totalIncome: 0,
          totalExpense: 50000,
          balance: -50000,
          transactionCount: 1,
          byCategory: [],
        ).savingsRate,
        isNull,
      );
    });
  });
}
