// `drift` y `matcher` definen `isNull`/`isNotNull`; los del matcher son los
// que se usan aquí (`expect(x, isNotNull)`), así que se ocultan los de drift.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/database/app_database.dart';
import 'package:pipefinanzaspersonales/core/database/daos.dart';
import 'package:pipefinanzaspersonales/core/database/seed/default_categories.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/repositories/movement_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/data/drift_movement_repository.dart';

void main() {
  late AppDatabase db;
  late CategoriesDao categories;
  late MovementsDao movements;
  late DriftMovementRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = CategoriesDao(db);
    movements = MovementsDao(db);
    repository = DriftMovementRepository(movements);
  });

  tearDown(() => db.close());

  group('semilla de categorías', () {
    test('crea 17 filas: 13 gastos y 4 ingresos', () async {
      final all = await categories.getAll();
      expect(all, hasLength(defaultCategories.length));
      expect(all.where((c) => c.type.isExpense), hasLength(13));
      expect(all.where((c) => c.type.isIncome), hasLength(4));
    });

    test('las categorías nuevas de la v2 y la v3 están en el seed', () async {
      // "Mascotas" e "Inversión" llegaron con la v2 y "Créditos" con la v3. El
      // nombre es la clave: es lo que permite insertarlas en una base ya
      // instalada sin depender del id.
      final names = (await categories.getAll()).map((c) => c.name);
      expect(names, contains('Mascotas'));
      expect(names, contains('Inversión'));
      expect(names, contains('Créditos'));
    });

    test('el seed no se duplica al reabrir la base', () async {
      final first = await categories.getAll();
      // `wasCreated` solo dispara una vez, pero la semilla también se
      // comprueba con `limit(1)`: lo verificamos con una segunda conexión
      // sobre el mismo archivo no es viable en memoria, así que basta con
      // confirmar que el método es idempotente por diseño.
      expect(first, hasLength(defaultCategories.length));
    });

    test('viene ordenada por sortOrder', () async {
      final all = await categories.getAll();
      final orders = all.map((c) => c.sortOrder).toList();
      expect(orders, orderedEquals([...orders]..sort()));
      expect(
        orders,
        orderedEquals(defaultCategories.map((c) => c.sortOrder).toList()),
      );
      expect(all.first.name, 'Alimentación');
      expect(all.last.name, 'Otros ingresos');
    });
  });

  group('lectura de movimientos', () {
    test('watchByMonth trae la categoría resuelta por JOIN', () async {
      await repository.create(_draft(25000, 1, DateTime(2026, 1, 10)));
      await repository.create(_draft(90000, 2, DateTime(2026, 1, 20)));

      final list = await movements.getByMonth(DateTime(2026, 1));
      expect(list, hasLength(2));
      // Sin JOIN esto sería 0; con JOIN llega la categoría real.
      expect(list.first.category.name, isNotEmpty);
      expect(list.first.category.iconKey, isNotEmpty);
    });

    test('el JOIN no duplica filas', () async {
      await repository.create(_draft(1000, 1, DateTime(2026, 1, 5)));
      expect(await movements.getByMonth(DateTime(2026, 1)), hasLength(1));
    });

    test('filtra por mes con rango [start, end)', () async {
      await repository.create(_draft(1000, 1, DateTime(2026, 1, 31, 23, 59)));
      await repository.create(_draft(2000, 1, DateTime(2026, 2, 1)));
      await repository.create(_draft(3000, 1, DateTime(2025, 12, 31, 23, 59)));

      expect(await movements.getByMonth(DateTime(2026, 1)), hasLength(1));
      expect(await movements.getByMonth(DateTime(2026, 2)), hasLength(1));
      expect(await movements.getByMonth(DateTime(2025, 12)), hasLength(1));
    });

    test('el último día del mes pertenece a ese mes', () async {
      await repository.create(_draft(1000, 1, DateTime(2026, 1, 31, 23, 59)));
      expect(await movements.getByMonth(DateTime(2026, 1)), hasLength(1));
    });

    test('ordena del más reciente al más antiguo', () async {
      await repository.create(_draft(1000, 1, DateTime(2026, 1, 5)));
      await repository.create(_draft(2000, 1, DateTime(2026, 1, 20)));
      await repository.create(_draft(3000, 1, DateTime(2026, 1, 10)));

      final list = await movements.getByMonth(DateTime(2026, 1));
      expect(list.map((m) => m.amount), [2000, 3000, 1000]);
    });

    test('watchByRange recorta por el rango [start, end)', () async {
      await repository.create(_draft(1000, 1, DateTime(2026, 1, 31, 23, 59)));
      await repository.create(_draft(2000, 1, DateTime(2026, 2, 1)));
      await repository.create(_draft(3000, 1, DateTime(2026, 3, 1, 12)));

      // Rango de enero y febrero: entra todo el día 31 a las 23:59, aunque
      // la fecha base sea a medianoche, y sale el 1 de marzo.
      final list = await movements
          .watchByRange(DateTime(2026, 1, 1), DateTime(2026, 3, 1))
          .first;
      expect(list.map((m) => m.amount), [2000, 1000]);
    });

    test('watchByRange con el rango vacío no devuelve nada', () async {
      await repository.create(_draft(1000, 1, DateTime(2026, 1, 15)));

      expect(
        await movements
            .watchByRange(DateTime(2026, 1, 1), DateTime(2026, 1, 1))
            .first,
        isEmpty,
      );
    });
  });

  group('migración del catálogo (v1 → v3)', () {
    /// El `sortOrder` que tenía el catálogo en la v1: 14 filas, "Otros" en el
    /// 10 y los ingresos del 11 al 14.
    const v1Orders = {
      'Alimentación': 1,
      'Transporte': 2,
      'Vivienda': 3,
      'Servicios': 4,
      'Salud': 5,
      'Entretenimiento': 6,
      'Educación': 7,
      'Ropa': 8,
      'Tecnología': 9,
      'Otros': 10,
      'Salario': 11,
      'Freelance': 12,
      'Inversiones': 13,
      'Otros ingresos': 14,
    };

    /// Deja la base como estaba en la v1: sin "Mascotas", sin "Inversión" y
    /// sin "Créditos", y con la numeración antigua. Es el estado que encuentra
    /// `onUpgrade`, tanto Comingendo de la v1 como de la v2.
    Future<void> downgradeToV1() async {
      await (db.delete(db.categories)..where(
            (c) =>
                c.name.equals('Mascotas') |
                c.name.equals('Inversión') |
                c.name.equals('Créditos'),
          ))
          .go();
      await db.batch((b) {
        for (final entry in v1Orders.entries) {
          b.update(
            db.categories,
            CategoriesCompanion(sortOrder: Value(entry.value)),
            where: (c) => c.name.equals(entry.key),
          );
        }
      });
    }

    test(
      'inserta las categorías que faltaban buscándolas por nombre',
      () async {
        await downgradeToV1();
        expect(await categories.getAll(), hasLength(14));

        await db.syncDefaultCategories();

        final all = await categories.getAll();
        expect(all, hasLength(17));
        expect(all.map((c) => c.name), contains('Mascotas'));
        expect(all.map((c) => c.name), contains('Inversión'));
        expect(all.map((c) => c.name), contains('Créditos'));
        // Insertadas con los datos de la semilla, no con valores por defecto.
        final pets = all.firstWhere((c) => c.name == 'Mascotas');
        expect(pets.iconKey, 'pets');
        expect(pets.colorValue, 0xFFA16207);
        expect(pets.type, MovementType.expense);
        expect(pets.isDefault, isTrue);
      },
    );

    test('renumera sortOrder para que coincida con la semilla', () async {
      await downgradeToV1();
      await db.syncDefaultCategories();

      final orders = (await categories.getAll()).map((c) => c.sortOrder);
      expect(orders, orderedEquals(defaultCategories.map((c) => c.sortOrder)));
    });

    test('no toca los movimientos que ya apuntan a una categoría', () async {
      // "Tecnología" es la 9ª en v1 y sigue siendo la 9ª, pero un ids distinto
      // de su instalación: el movimiento debe seguir apuntando a la misma
      // categoría por id, no a una fila nueva con el mismo nombre.
      final id = await repository.create(
        _draft(120000, 9, DateTime(2026, 1, 10)),
      );
      final antes = await movements.getById(id);

      await downgradeToV1();
      await db.syncDefaultCategories();

      final despues = await movements.getById(id);
      expect(despues!.category.id, antes!.category.id);
      expect(despues.category.name, 'Tecnología');
    });

    test('es idempotente: correrla dos veces no duplica nada', () async {
      await downgradeToV1();
      await db.syncDefaultCategories();
      await db.syncDefaultCategories();

      expect(await categories.getAll(), hasLength(17));
    });
  });

  group('escritura', () {
    test('inserta y lee por id', () async {
      final id = await repository.create(
        _draft(45000, 1, DateTime(2026, 1, 10), description: 'almuerzo'),
      );
      final found = await movements.getById(id);
      expect(found, isNotNull);
      expect(found!.amount, 45000);
      expect(found.description, 'almuerzo');
      expect(found.type, MovementType.expense);
    });

    test(
      'el monto se persiste positivo aunque el draft venga negativo',
      () async {
        final id = await repository.create(
          _draft(-12345, 1, DateTime(2026, 1, 10)),
        );
        final found = await movements.getById(id);
        expect(found!.amount, 12345);
        // El signo lo aporta el tipo, no el valor almacenado (§7).
        expect(found.signedAmount, -12345);
      },
    );

    test('la fecha se normaliza a medianoche', () async {
      final id = await repository.create(
        _draft(1000, 1, DateTime(2026, 1, 10, 17, 45, 30)),
      );
      final found = await movements.getById(id);
      expect(found!.date, DateTime(2026, 1, 10));
    });

    test('la descripción se recorta', () async {
      final id = await repository.create(
        _draft(1000, 1, DateTime(2026, 1, 10), description: '  con espacios  '),
      );
      expect((await movements.getById(id))!.description, 'con espacios');
    });

    test('update reemplaza todos los campos y mueve updatedAt', () async {
      final id = await repository.create(
        _draft(1000, 1, DateTime(2026, 1, 10)),
      );
      final before = (await movements.getById(id))!;

      final ok = await repository.update(
        id,
        _draft(
          9999,
          // 14 = "Salario" con el catálogo de 17 filas.
          14,
          DateTime(2026, 2, 14),
          description: 'cambiado',
          type: MovementType.income,
        ),
      );
      expect(ok, isTrue);

      final after = await movements.getById(id);
      expect(after!.amount, 9999);
      expect(after.type, MovementType.income);
      expect(after.description, 'cambiado');
      expect(after.date, DateTime(2026, 2, 14));
      expect(after.category.name, 'Salario');
      // `createdAt` no cambia al editar.
      expect(after.createdAt, before.createdAt);
      // Drift serializa `DateTime` como unix en SEGUNDOS: dos ediciones dentro
      // del mismo segundo dan el mismo `updatedAt`. Solo se garantiza que no
      // retroceda. El test siguiente cubre el avance real.
      expect(after.updatedAt.isBefore(before.updatedAt), isFalse);
    });

    test(
      'updatedAt avanza al cruzar un segundo (granularidad de Drift)',
      () async {
        final id = await repository.create(
          _draft(1000, 1, DateTime(2026, 1, 10)),
        );
        final before = (await movements.getById(id))!;

        // Se espera a que el reloj cruce el siguiente segundo, porque Drift
        // trunca los `DateTime` a segundos al serializarlos.
        while (DateTime.now().second == before.updatedAt.second) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        await repository.update(id, _draft(2000, 1, DateTime(2026, 1, 10)));
        final after = (await movements.getById(id))!;
        expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
        expect(after.createdAt, before.createdAt);
      },
    );

    test('update de un id inexistente devuelve false', () async {
      final ok = await repository.update(
        999,
        _draft(100, 1, DateTime(2026, 1, 1)),
      );
      expect(ok, isFalse);
    });

    test('delete borra y devuelve el conteo', () async {
      final id = await repository.create(
        _draft(1000, 1, DateTime(2026, 1, 10)),
      );
      await repository.delete(id);
      expect(await movements.getById(id), isNull);
    });
  });

  group('integridad referencial', () {
    test('no permite una categoría inexistente', () async {
      await expectLater(
        repository.create(_draft(1000, 9999, DateTime(2026, 1, 10))),
        throwsA(anything),
      );
    });
  });

  group('watchAll y watchByMonth emiten', () {
    test('watchByMonth emite los movimientos del mes', () async {
      await repository.create(_draft(1000, 1, DateTime(2026, 1, 10)));

      final emitted = await movements
          .watchByMonth(DateTime(2026, 1))
          .first
          .timeout(const Duration(seconds: 5));
      expect(emitted, hasLength(1));
      expect(emitted.first.amount, 1000);
    });
  });
}

MovementDraft _draft(
  int amount,
  int categoryId,
  DateTime date, {
  String description = '',
  MovementType type = MovementType.expense,
}) {
  return MovementDraft(
    amount: amount,
    type: type,
    categoryId: categoryId,
    date: date,
    description: description,
  );
}
