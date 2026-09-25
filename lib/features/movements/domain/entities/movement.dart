import 'category.dart';
import 'movement_type.dart';

/// §28 — Movimiento. `amount` en COP enteros y siempre positivo (D6).
/// `id` es 0 mientras el movimiento no ha sido persistido.
class Movement {
  const Movement({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int amount;
  final MovementType type;
  final Category category;
  final DateTime date;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isIncome => type.isIncome;

  /// Monto con signo, para sumas. Es la única fuente de la verdad del
  /// signo (§7): el valor persistido nunca es negativo.
  int get signedAmount => type.sign * amount;

  /// Copia inmutable con los campos de negocio actualizados. El `id` no cambia.
  Movement copyWith({
    int? amount,
    MovementType? type,
    Category? category,
    DateTime? date,
    String? description,
    DateTime? updatedAt,
  }) {
    return Movement(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Movement && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
