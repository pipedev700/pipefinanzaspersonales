import 'package:drift/drift.dart';

import '../../features/movements/domain/entities/movement_type.dart';

/// §28 — Categories. 14 filas de solo lectura en el MVP (S03 no las borra).
/// El `@DataClassName` evita la colisión con la entidad de dominio
/// `Category` (D13).
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconKey => text().withLength(min: 1, max: 40)();
  IntColumn get colorValue => integer()();
  IntColumn get type => intEnum<MovementType>()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// §28 — Movements. `amount` en COP enteros y SIEMPRE positivo (D6);
/// el signo lo determina `type` (§7).
@DataClassName('MovementRow')
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  IntColumn get type => intEnum<MovementType>()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().withDefault(const Constant(''))();

  // Drift serializa `DateTime` como unix en SEGUNDOS. `createdAt` y
  // `updatedAt` son metadatos que la UI del MVP no muestra, así que la
  // granularidad no afecta al usuario. Si alguna vez hace falta al
  // milisegundo, usar `.storeDateTimeAsText()` (ISO-8601) y una migración.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Índices de SQL. Los límites de negocio (§15) se aplican en la capa de
/// dominio: SQLite no soporta CHECK de forma portable a través de Drift.
abstract final class SchemaIndexes {
  /// Consulta mensual del dashboard y filtro del historial.
  static const byDate =
      'CREATE INDEX IF NOT EXISTS idx_movements_date '
      'ON movements (date DESC)';

  static const byCategory =
      'CREATE INDEX IF NOT EXISTS idx_movements_category '
      'ON movements (category_id)';

  static const all = [byDate, byCategory];
}
