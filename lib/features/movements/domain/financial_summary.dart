import 'entities/category.dart';
import 'entities/movement.dart';
import 'financial_calculator.dart';
import 'financial_values.dart';

/// Lo que pinta el dashboard. Se calcula **siempre** en memoria, nunca se
/// guarda en la base (§D11): así las reglas no pueden quedar desincronizadas
/// con los movimientos.
class FinancialSummary {
  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
    required this.byCategory,
  });

  /// Constructor derivado: delega todo el cálculo en [FinancialCalculator].
  /// Es lo que se usa en producción; el otro existe para poder testear sin
  /// calcular nada.
  ///
  /// Las categorías se necesitan para el desglose: sin ellas solo se sabría
  /// el id, no el nombre, el color ni el icono.
  factory FinancialSummary.from(
    List<Movement> movements,
    List<Category> categories,
  ) {
    const calc = FinancialCalculator();
    return FinancialSummary(
      totalIncome: calc.totalIncome(movements),
      totalExpense: calc.totalExpense(movements),
      balance: calc.balance(movements),
      transactionCount: movements.length,
      byCategory: calc.breakdownByCategory(movements, categories),
    );
  }

  final int totalIncome;
  final int totalExpense;

  /// Ingresos − gastos. Negativo significa que gastaste más de lo que entró.
  final int balance;

  final int transactionCount;

  /// Solo gastos, ordenado de mayor a menor.
  final List<CategoryBreakdown> byCategory;

  /// % de lo ingresado que quedó como ahorro. `null` si no hubo ingresos:
  /// dividir entre cero daría `Infinity`, y la UI prefiere no pintar nada.
  double? get savingsRate {
    if (totalIncome <= 0) return null;
    return _round1(balance * 100 / totalIncome);
  }

  static double _round1(double value) => (value * 10).round() / 10;
}
