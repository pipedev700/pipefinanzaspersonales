import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos.dart';
import '../domain/entities/movement.dart';
import '../domain/repositories/movement_repository.dart';

class DriftMovementRepository implements MovementRepository {
  DriftMovementRepository(this._dao);

  final MovementsDao _dao;

  @override
  Stream<List<Movement>> watchAll() => _dao.watchAll();

  @override
  Stream<List<Movement>> watchByMonth(DateTime month) => _dao.watchByMonth(month);

  @override
  Future<List<Movement>> getByMonth(DateTime month) => _dao.getByMonth(month);

  @override
  Future<List<Movement>> getAll() => _dao.getAll();

  @override
  Future<Movement?> getById(int id) => _dao.getById(id);

  @override
  Future<int> create(MovementDraft draft) =>
      _dao.insertMovement(_toCompanion(draft));

  @override
  Future<bool> update(int id, MovementDraft draft) =>
      _dao.updateMovementById(id, _toCompanion(draft));

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);

  /// `id`, `createdAt` y `updatedAt` los pone la base de datos.
  MovementsCompanion _toCompanion(MovementDraft draft) {
    final normalized = draft.normalized();
    return MovementsCompanion.insert(
      amount: normalized.amount,
      type: normalized.type,
      categoryId: normalized.categoryId,
      date: normalized.date,
      description: Value(normalized.description),
    );
  }
}
