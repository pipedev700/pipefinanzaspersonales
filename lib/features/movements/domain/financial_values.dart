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

  /// El valor exacto sin redondear, por si hay que pintar la barra.
  double get ratio => percentage / 100;
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
