import '../../../../features/movements/domain/entities/movement_type.dart';

/// §30 — Catálogo inicial. Semilla idempotente: se aplica una sola vez.
/// 13 categorías de gasto y 4 de ingreso.
///
/// `sortOrder` es **contiguo y sin huecos**, del 1 al 17, y los nombres son
/// la clave de identidad: la migración de v1 a v2 inserta por nombre y
/// renumera con esta misma lista, así que añadir una categoría aquí obliga a
/// subir `schemaVersion` en `app_database.dart`.
///
/// El orden deja "Otros" al final de su tipo: es la categoría de relleno y no
/// debe aparecer antes que las que sí describen el gasto.
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
  // ── Gastos (13) ────────────────────────────────────────────
  DefaultCategory(
    'Alimentación',
    'restaurant',
    0xFFF97316,
    MovementType.expense,
    1,
  ),
  DefaultCategory(
    'Transporte',
    'directions_bus',
    0xFF0EA5E9,
    MovementType.expense,
    2,
  ),
  DefaultCategory('Vivienda', 'home', 0xFF8B5CF6, MovementType.expense, 3),
  DefaultCategory('Servicios', 'bolt', 0xFFEAB308, MovementType.expense, 4),
  DefaultCategory('Salud', 'favorite', 0xFFEF4444, MovementType.expense, 5),
  DefaultCategory(
    'Entretenimiento',
    'movie',
    0xFFEC4899,
    MovementType.expense,
    6,
  ),
  DefaultCategory('Educación', 'school', 0xFF6366F1, MovementType.expense, 7),
  DefaultCategory('Ropa', 'shopping_bag', 0xFF14B8A6, MovementType.expense, 8),
  DefaultCategory('Tecnología', 'devices', 0xFF3B82F6, MovementType.expense, 9),
  DefaultCategory('Mascotas', 'pets', 0xFFA16207, MovementType.expense, 10),
  DefaultCategory(
    'Inversión',
    'savings_outlined',
    0xFF0F766E,
    MovementType.expense,
    11,
  ),
  DefaultCategory(
    'Créditos',
    'credit_card',
    0xFFDB2777,
    MovementType.expense,
    12,
  ),
  DefaultCategory('Otros', 'more_horiz', 0xFF64748B, MovementType.expense, 13),
  // ── Ingresos (4) ───────────────────────────────────────────
  DefaultCategory('Salario', 'work', 0xFF16A34A, MovementType.income, 14),
  DefaultCategory(
    'Freelance',
    'laptop_mac',
    0xFF22C55E,
    MovementType.income,
    15,
  ),
  DefaultCategory(
    'Inversiones',
    'trending_up',
    0xFF10B981,
    MovementType.income,
    16,
  ),
  DefaultCategory(
    'Otros ingresos',
    'savings',
    0xFF059669,
    MovementType.income,
    17,
  ),
];
