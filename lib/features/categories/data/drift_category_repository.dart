import '../../../../core/database/daos.dart';
import '../domain/repositories/category_repository.dart';
import '../../movements/domain/entities/category.dart';

/// `Category` vive en la feature `movements` porque un movimiento la
/// referencia. La feature `categories` depende de ella, nunca al revés:
/// así no hay ciclo entre las dos capas de dominio.
class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._dao);

  final CategoriesDao _dao;

  @override
  Stream<List<Category>> watchAll() => _dao.watchAll();

  @override
  Future<List<Category>> getAll() => _dao.getAll();

  @override
  Future<Category?> getById(int id) => _dao.getById(id);
}
