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
      expect(all, hasLength(17));
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
      expect(emitted.single, hasLength(17));
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
      // 14 = "Salario" con el catálogo de 17 filas. Se busca por id porque el
      // DAO recibe el id, no el nombre.
      final id = await movements.create(
        _draft(45000, 14, DateTime(2026, 1, 10)),
      );
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
      expect(
        updated.createdAt,
        created.createdAt,
        reason: 'createdAt es inmutable',
      );
      expect(updated.id, created.id);

      await movements.delete(id);
      expect(await movements.getById(id), isNull);
    });

    test('editar uno no toca los demás movimientos de la tabla', () async {
      // Este es el caso que faltaba y el que rompía la app: el `UPDATE` se
      // generaba sin `WHERE`, así que con dos o más filas en la tabla SQLite
      // fallaba con "UNIQUE constraint failed: movements.id" y el formulario
      // respondía "No se pudo guardar". Con una sola fila el `UPDATE` sin
      // `WHERE` es indistinguible del correcto, por eso hace falta más de un
      // registro en la tabla.
      final primero = await movements.create(
        _draft(11111, 1, DateTime(2026, 1, 5), description: 'a'),
      );
      final segundo = await movements.create(
        _draft(22222, 2, DateTime(2026, 1, 6), description: 'b'),
      );

      final ok = await movements.update(
        segundo,
        _draft(33333, 3, DateTime(2026, 1, 7), description: 'editado'),
      );
      expect(ok, isTrue, reason: 'no debe lanzar por colisión de id');

      final tras = await movements.getAll();
      expect(tras.map((m) => m.amount).toList()..sort(), [11111, 33333]);
      expect(
        (await movements.getById(primero))!.description,
        'a',
        reason: 'el otro movimiento no se puede mover de sitio ni de amount',
      );
    });

    test('editar un id inexistente devuelve false y no lanza', () async {
      await movements.create(_draft(1000, 1, DateTime(2026, 1, 5)));
      expect(
        await movements.update(9999, _draft(2000, 1, DateTime(2026, 1, 6))),
        isFalse,
      );
    });

    test('el tipo de ingreso sobrevive al round-trip', () async {
      final id = await movements.create(
        _draft(900000, 13, DateTime(2026, 1, 31), type: MovementType.income),
      );
      final found = await movements.getById(id);

      expect(found!.type, MovementType.income);
      expect(found.isIncome, isTrue);
      expect(found.signedAmount, 900000, reason: 'el ingreso suma (§7)');
    });

    test('editar a gasto invierte el signo sin tocar el monto', () async {
      final id = await movements.create(
        _draft(900000, 13, DateTime(2026, 1, 31), type: MovementType.income),
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
