import 'entities/category.dart';
import 'entities/movement.dart';
import 'entities/movement_type.dart';
import 'financial_values.dart';

/// D11 — Funciones puras. Sin Flutter, sin Drift, sin estado.
///
/// Todas devuelven `0` / lista vacía / `0.0` en vez de lanzar: el dashboard
/// tiene que poder pintar con la base recién creada y vacía.
class FinancialCalculator {
  const FinancialCalculator();

  /// El signo de `Movement.amount` lo determina `MovementType`, no el signo
  /// del número. `Movement.signedAmount` es la única fuente de la verdad del
  /// signo (§7): los montos se guardan positivos.
  int totalIncome(List<Movement> movements) => movements
      .where((m) => m.type == MovementType.income)
      .fold(0, (sum, m) => sum + m.amount);

  int totalExpense(List<Movement> movements) => movements
      .where((m) => m.type == MovementType.expense)
      .fold(0, (sum, m) => sum + m.amount);

  int balance(List<Movement> movements) =>
      movements.fold(0, (sum, m) => sum + m.signedAmount);

  /// §13 — Desglose de gastos por categoría, de mayor a menor.
  ///
  /// `total == 0` no puede ocurrir (si hay gastos, el total es > 0), pero si
  /// llegara, los porcentajes salen en 0 en lugar de dividir entre cero. Los
  /// grupos se conservan para que la UI pueda seguir mostrando los nombres.
  List<CategoryBreakdown> breakdownByCategory(
    List<Movement> movements,
    List<Category> categories,
  ) {
    final expenses = movements
        .where((m) => m.type == MovementType.expense)
        .toList(growable: false);
    if (expenses.isEmpty) return const [];

    final total = totalExpense(expenses);
    final byCategory = <int, int>{};
    for (final m in expenses) {
      byCategory[m.category.id] = (byCategory[m.category.id] ?? 0) + m.amount;
    }

    final breakdowns = <CategoryBreakdown>[];
    for (final entry in byCategory.entries) {
      final category = _find(categories, entry.key);
      final ratio = total == 0 ? 0.0 : entry.value * 100 / total;
      breakdowns.add(
        CategoryBreakdown(
          categoryId: entry.key,
          categoryName: category?.name ?? 'Sin categoría',
          colorValue: category?.colorValue ?? 0xFF94A3B8,
          iconKey: category?.iconKey ?? 'help',
          amount: entry.value,
          percentage: _round1(ratio),
        ),
      );
    }

    breakdowns.sort((a, b) => b.amount.compareTo(a.amount));
    return breakdowns;
  }

  /// §13 — Agrupación por día para el historial. Conserva el orden en que
  /// llegan los movimientos (el DAO ya los entrega desc por fecha), y calcula
  /// los subtotales de cada día.
  List<DailyGroup> groupByDay(List<Movement> movements) {
    final order = <DateTime>[];
    final groups = <DateTime, List<Movement>>{};

    for (final m in movements) {
      final day = DateTime(m.date.year, m.date.month, m.date.day);
      groups
          .putIfAbsent(day, () {
            order.add(day);
            return <Movement>[];
          })
          .add(m);
    }

    return order
        .map((day) {
          final items = groups[day]!;
          return DailyGroup(
            date: day,
            movements: items,
            totalIncome: totalIncome(items),
            totalExpense: totalExpense(items),
          );
        })
        .toList(growable: false);
  }

  /// §11 — Promedio de gasto mensual, calculada sobre los meses que tienen
  /// movimientos. `count` fija cuántos meses mira hacia atrás.
  int monthlyAverage(List<Movement> movements, int count) {
    if (movements.isEmpty || count <= 0) return 0;

    final buckets = <int, int>{};
    for (final m in movements) {
      if (m.type != MovementType.expense) continue;
      final key = m.date.year * 12 + m.date.month;
      buckets[key] = (buckets[key] ?? 0) + m.amount;
    }
    if (buckets.isEmpty) return 0;

    final total = buckets.values.fold(0, (a, b) => a + b);
    return (total / buckets.length).round();
  }

  /// §12 — Ingresos y gastos de los últimos [count] meses, **de más antiguo a
  /// más reciente**, para que el gráfico de S07 se lea de izquierda a derecha.
  List<MonthlyBar> lastMonths(
    List<Movement> movements,
    int count,
    DateTime ref,
  ) {
    if (count <= 0) return const [];

    final income = <int, int>{};
    final expense = <int, int>{};
    for (final m in movements) {
      final key = m.date.year * 12 + m.date.month;
      if (m.type == MovementType.income) {
        income[key] = (income[key] ?? 0) + m.amount;
      } else {
        expense[key] = (expense[key] ?? 0) + m.amount;
      }
    }

    return List.generate(count, (i) {
      // El índice 0 es el mes más antiguo de la ventana, no el de referencia.
      // `DateTime` normaliza meses <= 0 hacia el año anterior.
      final month = DateTime(ref.year, ref.month - (count - 1 - i));
      final key = month.year * 12 + month.month;
      return MonthlyBar(
        month: month,
        income: income[key] ?? 0,
        expense: expense[key] ?? 0,
      );
    }, growable: false);
  }

  static Category? _find(List<Category> categories, int id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  static double _round1(double value) => (value * 10).round() / 10;
}
