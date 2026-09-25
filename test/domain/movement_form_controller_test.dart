import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/features/categories/domain/repositories/category_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/repositories/movement_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/providers/history_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/providers/movement_form_controller.dart';

import '../helpers/fakes.dart';

/// Igual que en S03: hay que **mantener viva la suscripción** con `listen` y
/// esperar con tope de intentos, nunca con `.future`.
ProviderContainer makeContainer(
  MovementRepository movements, {
  CategoryRepository? categories,
}) {
  final container = ProviderContainer(
    overrides: [
      movementRepositoryProvider.overrideWithValue(movements),
      categoryRepositoryProvider.overrideWithValue(
        categories ?? FakeCategoryRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late FakeMovementRepository movements;

  setUp(() => movements = FakeMovementRepository());
  tearDown(() => movements.dispose());

  group('SelectedMonth', () {
    test('empieza en el mes actual', () {
      final now = DateTime.now();
      final container = makeContainer(movements);
      expect(
        container.read(selectedMonthProvider),
        DateTime(now.year, now.month),
      );
    });

    test('previous retrocede y cruza el año', () {
      final container = makeContainer(movements);
      final notifier = container.read(selectedMonthProvider.notifier);
      final inicio = container.read(selectedMonthProvider);

      notifier.previous();
      expect(
        container.read(selectedMonthProvider),
        DateTime(inicio.year, inicio.month - 1),
      );

      // Restar meses normaliza hacia el año anterior sin casos especiales.
      notifier.goTo(DateTime(2026, 1));
      notifier.previous();
      expect(container.read(selectedMonthProvider), DateTime(2025, 12));
    });

    test('next no pasa del mes actual', () {
      final now = DateTime.now();
      final container = makeContainer(movements);
      final notifier = container.read(selectedMonthProvider.notifier);

      // Desde el mes actual, avanzar no debe hacer nada.
      notifier.next();
      expect(container.read(selectedMonthProvider), DateTime(now.year, now.month));

      // Pero desde un mes pasado sí avanza.
      notifier.goTo(DateTime(2025, 5));
      notifier.next();
      expect(container.read(selectedMonthProvider), DateTime(2025, 6));
    });

    test('goTo normaliza a primer día del mes', () {
      final container = makeContainer(movements);
      container
          .read(selectedMonthProvider.notifier)
          .goTo(DateTime(2026, 7, 28));
      expect(container.read(selectedMonthProvider), DateTime(2026, 7));
    });
  });

  group('movementFormProvider — creación', () {
    test('arranca como gasto de hoy, sin categoría', () {
      final container = makeContainer(movements);
      final state = container.read(movementFormProvider);
      final now = DateTime.now();

      expect(state.isEditing, isFalse);
      expect(state.type, MovementType.expense);
      expect(state.categoryId, isNull);
      expect(state.date, DateTime(now.year, now.month, now.day));
      expect(state.amount, '');
    });

    test('no guarda sin monto', () async {
      final container = makeContainer(movements);
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setCategory(1);

      expect(await notifier.save(), isFalse);
      expect(
        container.read(movementFormProvider).saveError,
        'Ingresa un monto',
      );
      expect(movements.total, 0);
    });

    test('no guarda sin categoría', () async {
      final container = makeContainer(movements);
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setAmount('25000');

      expect(await notifier.save(), isFalse);
      expect(
        container.read(movementFormProvider).saveError,
        'Selecciona una categoría',
      );
    });

    test('no guarda con monto cero o negativo', () async {
      final container = makeContainer(movements);
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setCategory(1);

      notifier.setAmount('0');
      expect(await notifier.save(), isFalse);
      expect(
        container.read(movementFormProvider).saveError,
        'El monto debe ser mayor a cero',
      );

      notifier.setAmount('-50');
      expect(await notifier.save(), isFalse);
    });

    test('no guarda con fecha futura', () async {
      final container = makeContainer(movements);
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setAmount('25000');
      notifier.setCategory(1);
      final manana = DateTime.now().add(const Duration(days: 1));
      notifier.setDate(manana);

      expect(await notifier.save(), isFalse);
      expect(
        container.read(movementFormProvider).saveError,
        'La fecha no puede ser futura',
      );
    });

    test('guarda un movimiento válido y limpia isSaving', () async {
      final container = makeContainer(movements);
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setAmount('25000');
      notifier.setCategory(1);
      notifier.setDescription('  almuerzo  ');

      expect(await notifier.save(), isTrue);
      expect(container.read(movementFormProvider).isSaving, isFalse);
      expect(movements.total, 1);

      final guardado = movements.creados.single;
      expect(guardado.amount, 25000);
      expect(guardado.categoryId, 1);
      // `normalized()` recorta la descripción.
      expect(guardado.description, 'almuerzo');
      expect(guardado.date.hour, 0);
    });

    test('cambiar de tipo limpia la categoría', () async {
      final container = makeContainer(movements);
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setCategory(1);
      expect(container.read(movementFormProvider).categoryId, 1);

      notifier.setType(MovementType.income);
      expect(container.read(movementFormProvider).categoryId, isNull);
    });

    test('editar cualquier campo borra el error de guardado', () async {
      final container = makeContainer(movements);
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setCategory(1);
      await notifier.save();
      expect(container.read(movementFormProvider).saveError, isNotNull);

      notifier.setAmount('1000');
      expect(container.read(movementFormProvider).saveError, isNull);
    });
  });

  group('movementFormProvider — edición', () {
    late Movement existente;
    late FakeMovementRepository repoConMovimiento;

    setUp(() {
      existente = Movement(
        id: 42,
        amount: 45000,
        type: MovementType.income,
        category: buildCategory(id: 3, name: 'Salario'),
        date: DateTime(2026, 2, 10),
        description: 'Nómina',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repoConMovimiento = FakeMovementRepository([existente]);
    });
    tearDown(() => repoConMovimiento.dispose());

    test('load precarga todos los campos', () async {
      final container = makeContainer(repoConMovimiento);
      await container.read(movementFormProvider.notifier).load(42);
      final state = container.read(movementFormProvider);

      expect(state.isEditing, isTrue);
      expect(state.id, 42);
      expect(state.amount, '45000');
      expect(state.type, MovementType.income);
      expect(state.categoryId, 3);
      expect(state.date, DateTime(2026, 2, 10));
      expect(state.description, 'Nómina');
      expect(state.isLoading, isFalse);
    });

    test('load(null) deja el formulario en modo creación', () async {
      final container = makeContainer(repoConMovimiento);
      await container.read(movementFormProvider.notifier).load(null);
      expect(container.read(movementFormProvider).isEditing, isFalse);
    });

    test('un id inexistente degrada a creación sin colgarse', () async {
      final container = makeContainer(repoConMovimiento);
      await container.read(movementFormProvider.notifier).load(999);
      final state = container.read(movementFormProvider);

      expect(state.isEditing, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.date, isNotNull);
    });

    test('save actualiza en vez de crear', () async {
      final container = makeContainer(repoConMovimiento);
      final notifier = container.read(movementFormProvider.notifier);
      await notifier.load(42);
      notifier.setAmount('50000');

      expect(await notifier.save(), isTrue);
      expect(repoConMovimiento.creados, isEmpty);
      expect(repoConMovimiento.total, 1);
      expect(repoConMovimiento.list.first.amount, 50000);
    });

    test('no guarda mientras está cargando', () async {
      final container = makeContainer(repoConMovimiento);
      final notifier = container.read(movementFormProvider.notifier);
      final futuro = notifier.load(42);

      // El estado aún no tiene id: sin este candado se crearía un duplicado.
      expect(await notifier.save(), isFalse);
      await futuro;
    });
  });

  group('fallos del repositorio', () {
    test('un error al guardar no deja el botón colgado', () async {
      final container = makeContainer(_FailingMovementRepository());
      final notifier = container.read(movementFormProvider.notifier);
      notifier.setAmount('25000');
      notifier.setCategory(1);

      expect(await notifier.save(), isFalse);
      final state = container.read(movementFormProvider);
      expect(state.isSaving, isFalse);
      expect(state.saveError, 'No se pudo guardar. Intenta de nuevo.');
    });
  });
}

/// Repositorio que falla al escribir.
class _FailingMovementRepository implements MovementRepository {
  @override
  Stream<List<Movement>> watchAll() => const Stream.empty();

  @override
  Stream<List<Movement>> watchByMonth(DateTime month) => const Stream.empty();

  @override
  Future<List<Movement>> getAll() async => const [];

  @override
  Future<List<Movement>> getByMonth(DateTime month) async => const [];

  @override
  Future<Movement?> getById(int id) async => null;

  @override
  Future<int> create(MovementDraft draft) async => throw StateError('disco lleno');

  @override
  Future<bool> update(int id, MovementDraft draft) async =>
      throw StateError('disco lleno');

  @override
  Future<void> delete(int id) async => throw StateError('disco lleno');
}
