import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/features/categories/domain/repositories/category_repository.dart';
import 'package:pipefinanzaspersonales/features/categories/presentation/providers/category_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/category.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';

import '../helpers/await_first_value.dart';
import '../helpers/fakes.dart';

/// Estos son tests de *lógica de provider*, no de widgets: no hay árbol de
/// widgets que montar, así que se usa un `ProviderContainer` directo en vez
/// de `testWidgets`. Evita además la trampa de `tester.pump()`, donde el
/// reloj falso no siempre deja avanzar la suscripción al stream.
///
/// La suscripción explícita a `categoriesProvider` es obligatoria: sin un
/// `listen`, `container.read` sobre un `StreamProvider` puede no dejar viva la
/// suscripción y el valor nunca llega.
ProviderContainer makeContainer(CategoryRepository repo) {
  final container = ProviderContainer(
    overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  container.listen(categoriesProvider, (_, _) {});
  return container;
}

void main() {
  late FakeCategoryRepository repo;

  setUp(() => repo = FakeCategoryRepository());
  tearDown(() => repo.dispose());

  Future<List<Category>> firstValue(ProviderContainer c) => awaitFirstValue(
    () => c.read(categoriesProvider),
    description: 'categoriesProvider',
  );

  test('categoriesProvider expone el catálogo del repositorio', () async {
    final container = makeContainer(repo);
    final list = await firstValue(container);

    expect(list, hasLength(3));
    expect(list.first.name, 'Comida');
  });

  test('separa gastos e ingresos', () async {
    final container = makeContainer(repo);
    await firstValue(container);

    final expenses = container.read(expenseCategoriesProvider);
    final incomes = container.read(incomeCategoriesProvider);

    expect(expenses, hasLength(2));
    expect(incomes, hasLength(1));
    expect(expenses.every((c) => c.type == MovementType.expense), isTrue);
    expect(incomes.single.name, 'Salario');
  });

  test('respeta el orden de sortOrder', () async {
    final container = makeContainer(repo);
    await firstValue(container);

    // El orden viene del DAO (`ORDER BY sortOrder`); el provider no lo altera.
    expect(
      container.read(expenseCategoriesProvider).map((c) => c.name).toList(),
      ['Comida', 'Transporte'],
    );
  });

  test('catálogo vacío da listas vacías, no lanza', () async {
    final vacio = FakeCategoryRepository([]);
    final container = makeContainer(vacio);
    await firstValue(container);

    expect(container.read(expenseCategoriesProvider), isEmpty);
    expect(container.read(incomeCategoriesProvider), isEmpty);
    expect(container.read(categoryByIdProvider(1)), isNull);
    await vacio.dispose();
  });

  test('categoryByIdProvider resuelve y devuelve null si no existe', () async {
    final container = makeContainer(repo);
    await firstValue(container);

    expect(container.read(categoryByIdProvider(2))?.name, 'Transporte');
    expect(container.read(categoryByIdProvider(999)), isNull);
  });

  test('se reconstruye cuando el repositorio emite', () async {
    final container = makeContainer(repo);
    expect((await firstValue(container)).length, 3);
    expect(container.read(expenseCategoriesProvider), hasLength(2));

    repo.emit([
      buildCategory(id: 1, name: 'Comida', sortOrder: 1),
      buildCategory(id: 2, name: 'Transporte', sortOrder: 2),
      buildCategory(id: 3, name: 'Ocio', sortOrder: 3),
      buildCategory(id: 4, name: 'Regalo', sortOrder: 4),
    ]);

    final actualizada = await awaitFirstValue(
      () {
        final value = container.read(categoriesProvider);
        return value.hasValue && value.requireValue.length == 4
            ? value
            : const AsyncValue<List<Category>>.loading();
      },
      description: 'el catálogo con 4 categorías',
    );

    expect(actualizada, hasLength(4));
    expect(container.read(expenseCategoriesProvider), hasLength(4));
  });

  test('un error del repositorio no rompe los providers derivados', () async {
    final container = makeContainer(_ExplodingCategoryRepository());

    // El seed puede fallar (permisos, disco lleno). Los providers derivados
    // deben dar listas vacías, no propagar la excepción.
    await expectLater(
      awaitFirstValue(() => container.read(categoriesProvider)),
      throwsStateError,
    );
    expect(container.read(expenseCategoriesProvider), isEmpty);
    expect(container.read(incomeCategoriesProvider), isEmpty);
    expect(container.read(categoryByIdProvider(1)), isNull);
  });
}

/// Repositorio cuyo stream falla de inmediato.
class _ExplodingCategoryRepository implements CategoryRepository {
  @override
  Stream<List<Category>> watchAll() =>
      Stream<List<Category>>.error(StateError('fallo de disco'));

  @override
  Future<List<Category>> getAll() async => throw StateError('fallo de disco');

  @override
  Future<Category?> getById(int id) async => null;
}
