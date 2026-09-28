import 'movement_type.dart';

/// §28 — Categoría del catálogo. `iconKey` es una clave de texto, nunca un
/// codepoint de `IconData` (D9). `colorValue` es un ARGB entero.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.type,
    required this.isDefault,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String iconKey;
  final int colorValue;
  final MovementType type;
  final bool isDefault;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
