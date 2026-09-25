import '../../../../features/movements/domain/entities/movement_type.dart';

/// §30 — Catálogo inicial. Semilla idempotente: se aplica una sola vez.
/// 10 categorías de gasto y 4 de ingreso.
class DefaultCategory {
  const DefaultCategory(
    this.name,
    this.iconKey,
    this.colorValue,
    this.type,
    this.sortOrder,
  );

  final String name;
  final String iconKey;
  final int colorValue;
  final MovementType type;
  final int sortOrder;
}

const defaultCategories = <DefaultCategory>[
  // ── Gastos (10) ────────────────────────────────────────────
  DefaultCategory('Alimentación', 'restaurant', 0xFFF97316, MovementType.expense, 1),
  DefaultCategory('Transporte', 'directions_bus', 0xFF0EA5E9, MovementType.expense, 2),
  DefaultCategory('Vivienda', 'home', 0xFF8B5CF6, MovementType.expense, 3),
  DefaultCategory('Servicios', 'bolt', 0xFFEAB308, MovementType.expense, 4),
  DefaultCategory('Salud', 'favorite', 0xFFEF4444, MovementType.expense, 5),
  DefaultCategory('Entretenimiento', 'movie', 0xFFEC4899, MovementType.expense, 6),
  DefaultCategory('Educación', 'school', 0xFF6366F1, MovementType.expense, 7),
  DefaultCategory('Ropa', 'shopping_bag', 0xFF14B8A6, MovementType.expense, 8),
  DefaultCategory('Tecnología', 'devices', 0xFF3B82F6, MovementType.expense, 9),
  DefaultCategory('Otros', 'more_horiz', 0xFF64748B, MovementType.expense, 10),
  // ── Ingresos (4) ───────────────────────────────────────────
  DefaultCategory('Salario', 'work', 0xFF16A34A, MovementType.income, 11),
  DefaultCategory('Freelance', 'laptop_mac', 0xFF22C55E, MovementType.income, 12),
  DefaultCategory('Inversiones', 'trending_up', 0xFF10B981, MovementType.income, 13),
  DefaultCategory('Otros ingresos', 'savings', 0xFF059669, MovementType.income, 14),
];
