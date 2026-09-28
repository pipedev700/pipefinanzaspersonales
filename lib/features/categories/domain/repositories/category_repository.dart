import '../../../movements/domain/entities/category.dart';

/// El catálogo es de solo lectura en el MVP (§10).
abstract interface class CategoryRepository {
  Stream<List<Category>> watchAll();
  Future<List<Category>> getAll();
  Future<Category?> getById(int id);
}
