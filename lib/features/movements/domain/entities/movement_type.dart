/// §7 — El tipo determina el signo del monto. El monto siempre es positivo
/// (D6): nunca se guarda un valor negativo en la base de datos.
enum MovementType {
  income,
  expense;

  bool get isIncome => this == MovementType.income;
  bool get isExpense => this == MovementType.expense;

  /// Signo que este tipo aporta al balance (§32).
  int get sign => isIncome ? 1 : -1;

  String get label => switch (this) {
    MovementType.income => 'Ingreso',
    MovementType.expense => 'Gasto',
  };
}
