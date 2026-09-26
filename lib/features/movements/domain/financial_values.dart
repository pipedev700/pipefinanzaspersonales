import 'entities/movement.dart';

/// §13 — Desglose de una categoría dentro del período. Solo gastos.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.iconKey,
    required this.amount,
    required this.percentage,
  });

  final int categoryId;
  final String categoryName;
  final int colorValue;
  final String iconKey;
  final int amount;

  /// Porcentaje del total de gastos, redondeado a 1 decimal (0..100).
  final double percentage;
}

/// movements de un mismo día, con sus subtotales.
class DailyGroup {
  const DailyGroup({
    required this.date,
    required this.movements,
    required this.totalIncome,
    required this.totalExpense,
  });

  final DateTime date;
  final List<Movement> movements;
  final int totalIncome;
  final int totalExpense;

  /// Lo que el día **sumó**: ingresos menos gastos, con su signo.
  ///
  /// Es el número que va arriba del grupo. Antes se pintaba solo
  /// `totalExpense` con un `-` delante, así que un día con un sueldo de
  /// $3.000.000 y $100.000 de gastos salía en rojo como "-$100.000": la
  /// pantalla comunicaba un déficit donde no lo había, porque el ingreso no
  /// se sumaba en ninguna parte de esa línea.
  int get net => totalIncome - totalExpense;

  /// `true` si el día cerró en verde. Con `net == 0` se cuenta como
  /// positivo: no ganó ni perdió, y pintarlo en rojo sugeriría una pérdida.
  bool get isPositive => net >= 0;
}

/// Ingresos y gastos de un mes, para el gráfico comparativo de S07.
class MonthlyBar {
  const MonthlyBar({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;

  int get max => income > expense ? income : expense;
}
