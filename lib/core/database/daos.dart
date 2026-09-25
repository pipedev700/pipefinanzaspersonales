import 'package:drift/drift.dart';

import '../../features/movements/domain/entities/category.dart' as domain;
import '../../features/movements/domain/entities/movement.dart' as domain;
import 'app_database.dart';
import 'tables.dart';

part 'daos.g.dart';

/// §28 — Acceso a `categories`. Solo lectura: el catálogo es fijo en el
/// MVP (§10) y no tiene operaciones de escritura.
@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  SimpleSelectStatement<$CategoriesTable, CategoryRow> get _sorted =>
      attachedDatabase.select(categories)
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);

  Future<List<domain.Category>> getAll() async =>
      (await _sorted.get()).map(_toEntity).toList();

  Stream<List<domain.Category>> watchAll() =>
      _sorted.watch().map((rows) => rows.map(_toEntity).toList());

  Future<domain.Category?> getById(int id) async {
    final row = await (attachedDatabase.select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  domain.Category _toEntity(CategoryRow row) => domain.Category(
    id: row.id,
    name: row.name,
    iconKey: row.iconKey,
    colorValue: row.colorValue,
    type: row.type,
    isDefault: row.isDefault,
    sortOrder: row.sortOrder,
  );
}

/// §28 — Acceso a `movements`. Todas las lecturas traen la categoría
/// resuelta por JOIN, para evitar N+1.
@DriftAccessor(tables: [Movements, Categories])
class MovementsDao extends DatabaseAccessor<AppDatabase>
    with _$MovementsDaoMixin {
  MovementsDao(super.db);

  /// JOIN movimiento → categoría, ordenado del más reciente al más antiguo.
  ///
  /// Drift declara `join()` devolviendo `JoinedSelectStatement` sin argumentos
  /// explícitos, que Dart rellena con los bounds: el segundo parámetro queda
  /// en `dynamic` y el resultado se lee como `TypedResult`, de donde sale la
  /// categoría con `readTable`. Es el tipo correcto, aunque se vea raro.
  JoinedSelectStatement<HasResultSet, dynamic> _joined() {
    return attachedDatabase.select(movements).join([
      innerJoin(
        categories,
        categories.id.equalsExp(movements.categoryId),
      ),
    ])..orderBy([OrderingTerm.desc(movements.date)]);
  }

  Stream<List<domain.Movement>> watchAll() =>
      _joined().watch().map(_toEntities);

  /// D12 — El rango de fechas se filtra en SQL para traer pocos rows; los
  /// cálculos financieros van en Dart (S02).
  Stream<List<domain.Movement>> watchByMonth(DateTime month) {
    final range = monthRange(month);
    return (_joined()
          ..where(
            movements.date.isBiggerOrEqualValue(range.start) &
                movements.date.isSmallerThanValue(range.end),
          ))
        .watch()
        .map(_toEntities);
  }

  Future<List<domain.Movement>> getByMonth(DateTime month) async {
    final range = monthRange(month);
    return _toEntities(
      await (_joined()
            ..where(
              movements.date.isBiggerOrEqualValue(range.start) &
                  movements.date.isSmallerThanValue(range.end),
            ))
          .get(),
    );
  }

  Future<List<domain.Movement>> getAll() async => _toEntities(await _joined().get());

  Future<domain.Movement?> getById(int id) async {
    final row =
        await (_joined()..where(movements.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row.readTable(movements), row.readTable(categories));
  }

  Future<int> insertMovement(MovementsCompanion entry) =>
      attachedDatabase.into(movements).insert(entry);

  /// `write` (no `replace`) a propósito: `replace` reescribe TODAS las
  /// columnas, y como el companion no lleva `createdAt`, la base le pondría
  /// una marca de tiempo nueva en cada edición. `write` solo toca las
  /// columnas presentes, así que `createdAt` se preserva.
  ///
  /// `write` devuelve el número de filas afectadas: se traduce a `bool`
  /// porque "no había fila con ese id" es el único caso de fallo posible.
  Future<bool> updateMovementById(int id, MovementsCompanion entry) async {
    final changed = await attachedDatabase.update(movements).write(
      entry.copyWith(
        id: Value(id),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return changed > 0;
  }

  Future<int> deleteById(int id) =>
      (attachedDatabase.delete(movements)..where((m) => m.id.equals(id))).go();

  List<domain.Movement> _toEntities(List<TypedResult> rows) => rows
      .map(
        (r) => _toEntity(
          r.readTable(movements),
          r.readTable(categories),
        ),
      )
      .toList();

  domain.Movement _toEntity(MovementRow m, CategoryRow c) => domain.Movement(
    id: m.id,
    amount: m.amount,
    type: m.type,
    category: domain.Category(
      id: c.id,
      name: c.name,
      iconKey: c.iconKey,
      colorValue: c.colorValue,
      type: c.type,
      isDefault: c.isDefault,
      sortOrder: c.sortOrder,
    ),
    date: m.date,
    description: m.description,
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
  );

  /// Rango [start, end) del mes: el último día a medianoche del mes
  /// siguiente. Comparable y seguro para índices. Es un record, no el
  /// `DateTimeRange` de Flutter: la capa de datos no depende de Flutter.
  static ({DateTime start, DateTime end}) monthRange(DateTime month) => (
    start: DateTime(month.year, month.month),
    end: DateTime(month.year, month.month + 1),
  );
}
