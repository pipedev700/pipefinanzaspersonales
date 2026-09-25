import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/database/app_database.dart';
import 'package:pipefinanzaspersonales/core/database/daos.dart';
import 'package:pipefinanzaspersonales/features/categories/data/drift_category_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/data/drift_movement_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/repositories/movement_repository.dart';

/// S08 — El **contrato de los repositorios** contra una base de datos real.
///
/// `app_database_test.dart` (S01) probó los DAOs. Eso deja fuera justo la
/// capa que consume `presentation`: los repositorios. Aquí se prueba el
/// contrato tal y como lo ve la aplicación, con las mismas interfaces que
/// los fakes sustituyen en los tests de widget. Si un cambio rompe el
/// repositorio pero no el DAO (por ejemplo, que `getById` deje de resolver
/// el JOIN), estos tests lo detectan; los de S01 no.
void main() {
  late AppDatabase db;
  late DriftCategoryRepository categories;
  late DriftMovementRepository movements;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = DriftCategoryRepository(CategoriesDao(db));
    movements = DriftMovementRepository(MovementsDao(db));
  });

  tearDown(() => db.close());

  /// Reúne [count] emisiones del stream y corta la suscripción.
  ///
  /// `stream.first` solo ve la primera: para comprobar que el stream
  /// **reemite** al escribir (de eso depende el dashboard para refrescarse
  /// sin recargar) hace falta quedarse escuchando.
  Future<List<T>> collect<T>(
    Stream<T> stream,
    int count, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final buffer = <T>[];
    final done = Completer<void>();
    final sub = stream.listen(
      (value) {
        buffer.add(value);
        if (buffer.length >= count && !done.isCompleted) done.complete();
      },
      onError: (Object error, StackTrace stack) {
        if (!done.isCompleted) done.completeError(error, stack);
      },
    );
    try {
      await done.future.timeout(
        timeout,
        onTimeout: () => fail(
          'Timeout: se esperaban $count emisiones y llegaron ${buffer.length}',
        ),
      );
    } finally {
      await sub.cancel();
    }
    return buffer;
  }

  group('DriftCategoryRepository', () {
    test('getAll devuelve el catálogo completo y ordenado', () async {
      final all = await categories.getAll();
      expect(all, hasLength(14));
      expect(
        all.map((c) => c.sortOrder),
        orderedEquals(all.map((c) => c.sortOrder).toList()..sort()),
      );
    });

    test('getById mapea todos los campos de la fila a la entidad', () async {
      final first = (await categories.getAll()).first;
      final found = await categories.getById(first.id);

      expect(found, isNotNull);
      expect(found!.id, first.id);
      expect(found.name, first.name);
      expect(found.iconKey, first.iconKey);
      expect(found.colorValue, first.colorValue);
      expect(found.type, first.type);
      expect(found.isDefault, isTrue);
      expect(found.sortOrder, first.sortOrder);
    });

    test('getById de un id inexistente devuelve null, no lanza', () async {
      expect(await categories.getById(9999), isNull);
    });

    test('watchAll emite el catálogo y sobrevive al flujo', () async {
      final emitted = await collect(categories.watchAll(), 1);
      expect(emitted.single, hasLength(14));
    });
  });

  group('lecturas de movimientos a través del repositorio', () {
    test('watchAll reemite cuando se escribe', () async {
      // Suscripción viva + escritura: el dashboard se actualiza solo, sin
      // recargar. `stream.first` no lo comprobaría, porque solo ve la
      // emisión inicial.
      final seen = <List<Movement>>[];
      final done = Completer<void>();
      final sub = movements.watchAll().listen((value) {
        seen.add(value);
        if (seen.length >= 2 && !done.isCompleted) done.complete();
      });
      await _pump();
      await movements.create(_draft(1000, 1, DateTime(2026, 1, 5)));
      await done.future.timeout(const Duration(seconds: 5));
      await sub.cancel();

      expect(seen.first, isEmpty, reason: 'primera emisión: base vacía');
      expect(seen.last, hasLength(1), reason: 'tras crear, reemite con 1');
      expect(seen.last.single.amount, 1000);
    });

    test('getAll ordena del más reciente al más antiguo', () async {
      await movements.create(_draft(1000, 1, DateTime(2026, 1, 5)));
      await movements.create(_draft(2000, 1, DateTime(2026, 3, 20)));
      await movements.create(_draft(3000, 1, DateTime(2026, 2, 10)));

      final all = await movements.getAll();
      expect(all.map((m) => m.amount), [2000, 3000, 1000]);
    });

    test('getById resuelve la categoría por JOIN', () async {
      final id = await movements.create(_draft(45000, 11, DateTime(2026, 1, 10)));
      final found = await movements.getById(id);

      expect(found, isNotNull);
      expect(found!.category.name, 'Salario');
      expect(found.category.iconKey, isNotEmpty);
      expect(found.category.type, MovementType.income);
    });

    test('getById de un id inexistente devuelve null', () async {
      expect(await movements.getById(4242), isNull);
    });

    test('getByMonth filtra por mes y watchByMonth también', () async {
      await movements.create(_draft(1000, 1, DateTime(2026, 1, 31, 23, 59)));
      await movements.create(_draft(2000, 1, DateTime(2026, 2, 1)));

      expect(await movements.getByMonth(DateTime(2026, 1)), hasLength(1));
      final streamed = await collect(
        movements.watchByMonth(DateTime(2026, 1)),
        1,
      );
      expect(streamed.single, hasLength(1));
      expect(streamed.single.single.amount, 1000);
    });
  });

  group('round-trip de escritura por la interfaz', () {
    test('crear, leer, editar y borrar', () async {
      final id = await movements.create(
        _draft(25000, 1, DateTime(2026, 1, 10), description: 'almuerzo'),
      );

      final created = await movements.getById(id);
      expect(created!.amount, 25000);
      expect(created.description, 'almuerzo');

      final ok = await movements.update(
        id,
        _draft(
          30000,
          2,
          DateTime(2026, 1, 12),
          description: 'bus',
          type: MovementType.income,
        ),
      );
      expect(ok, isTrue);

      final updated = await movements.getById(id);
      expect(updated!.amount, 30000);
      expect(updated.description, 'bus');
      expect(updated.date, DateTime(2026, 1, 12));
      expect(updated.category.name, 'Transporte');
      expect(updated.createdAt, created.createdAt, reason: 'createdAt es inmutable');
      expect(updated.id, created.id);

      await movements.delete(id);
      expect(await movements.getById(id), isNull);
    });

    test('el tipo de ingreso sobrevive al round-trip', () async {
      final id = await movements.create(
        _draft(900000, 11, DateTime(2026, 1, 31), type: MovementType.income),
      );
      final found = await movements.getById(id);

      expect(found!.type, MovementType.income);
      expect(found.isIncome, isTrue);
      expect(found.signedAmount, 900000, reason: 'el ingreso suma (§7)');
    });

    test('editar a gasto invierte el signo sin tocar el monto', () async {
      final id = await movements.create(
        _draft(900000, 11, DateTime(2026, 1, 31), type: MovementType.income),
      );
      await movements.update(
        id,
        _draft(900000, 1, DateTime(2026, 1, 31), type: MovementType.expense),
      );

      final found = await movements.getById(id);
      expect(found!.amount, 900000, reason: 'siempre positivo (D6)');
      expect(found.signedAmount, -900000, reason: 'el signo lo da el tipo');
    });
  });

  group('el enum se guarda por índice: reordenar rompe los datos', () {
    test('los valores persistidos siguen al enum actual', () async {
      // `intEnum<MovementType>()` guarda el **índice**, no el nombre. Si
      // alguien reordena el enum, las filas ya guardadas cambian de
      // significado en silencio: un gasto se convertiría en ingreso. Este
      // test falla el día que se reordene, que es justo cuando hay que
      // escribir una migración.
      expect(MovementType.values, [MovementType.income, MovementType.expense]);
      expect(MovementType.income.index, 0);
      expect(MovementType.expense.index, 1);
    });
  });
}

/// Un turno del bucle de eventos: deja que la escritura llegue al stream.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

MovementDraft _draft(
  int amount,
  int categoryId,
  DateTime date, {
  String description = '',
  MovementType type = MovementType.expense,
}) => MovementDraft(
  amount: amount,
  type: type,
  categoryId: categoryId,
  date: date,
  description: description,
);
