import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../movements/domain/entities/category.dart';

/// Stream: la lista se reconstruye sola si el catálogo cambia (§35).
///
/// Cada provider derivado usa `AsyncValue.value`, así que mientras no haya
/// datos devuelven `[]` y la UI puede pintar su estado vacío en vez de un
/// spinner infinito.
final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Helper único para no repetir el filtrado en los dos providers.
/// Preserva el orden que entrega el DAO (`ORDER BY sortOrder`).
List<Category> _filterByType(AsyncValue<List<Category>> source, bool isIncome) {
  final list = source.value;
  if (list == null) return const [];
  return list.where((c) => c.type.isIncome == isIncome).toList(growable: false);
}

/// Categorías de gasto para el selector (§12).
final expenseCategoriesProvider = Provider<List<Category>>(
  (ref) => _filterByType(ref.watch(categoriesProvider), false),
);

/// Categorías de ingreso para el selector (§12).
final incomeCategoriesProvider = Provider<List<Category>>(
  (ref) => _filterByType(ref.watch(categoriesProvider), true),
);

/// Catálogo completo indexado por id, para resolver la categoría seleccionada
/// en el formulario sin recorrer la lista.
///
/// `movementRepositoryProvider` ya devuelve cada `Movement` con su `Category`
/// embebida (JOIN de S01), así que esto solo hace falta al abrir el formulario
/// en modo edición, donde aún no hay ningún `Movement` que leer.
final categoryByIdProvider = Provider.family<Category?, int>((ref, id) {
  final list = ref.watch(categoriesProvider).value;
  if (list == null) return null;
  for (final category in list) {
    if (category.id == id) return category;
  }
  return null;
});
