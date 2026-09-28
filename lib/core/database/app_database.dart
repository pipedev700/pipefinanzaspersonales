import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/movements/domain/entities/movement_type.dart';
import 'daos.dart';
import 'seed/default_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// §36 — 100% local. Sin red, sin permisos, sin telemetría.
@DriftDatabase(
  tables: [Categories, Movements],
  daos: [CategoriesDao, MovementsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Solo para tests (§33). Ver la nota de plataforma de S08.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    // v2 — Categorías de gasto "Mascotas" e "Inversión".
    // v3 — Categoría de gasto "Créditos".
    //
    // `_seedCategories` no sirve aquí: es idempotente pero **solo si la tabla
    // está vacía**, y en una app ya instalada está llena. Sin `onUpgrade` el
    // usuario se quedaría sin las dos categorías nuevas para siempre, y como
    // el catálogo es de solo lectura (S03) no hay forma de añadirlas desde la
    // app.
    onUpgrade: (m, from, to) => syncDefaultCategories(),
    beforeOpen: (details) async {
      // `PRAGMA foreign_keys` debe ir en `beforeOpen`, no solo en `onCreate`:
      // es la única forma de que aplique a la conexión ya abierta.
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) await _seedCategories();
    },
  );

  Future<void> _createIndexes() async {
    for (final sql in SchemaIndexes.all) {
      await customStatement(sql);
    }
  }

  /// Inserta las categorías de [defaultCategories] que falten y renumera
  /// `sortOrder` de todas para que coincida con la semilla.
  ///
  /// El **nombre es la clave**: el id lo asigna SQLite y no se puede suponer
  /// (depende del autoincrement de cada instalación). Por eso no se busca por
  /// id sino por nombre, y por eso renumerar es seguro: solo toca
  /// `sortOrder`, nunca el nombre ni el tipo, así que los movimientos ya
  /// guardados siguen apuntando a la misma categoría.
  ///
  /// Idempotente: correrla dos veces no inserta nada nuevo.
  ///
  /// No es `private` para poder invocarla desde un test sobre una base ya
  /// sembrada: así se comprueba el `UPDATE` de `sortOrder` y el `INSERT` por
  /// nombre contra SQLite de verdad, no contra una imitación del algoritmo.
  Future<void> syncDefaultCategories() async {
    final idsByName = <String, int>{
      for (final row in await select(categories).get()) row.name: row.id,
    };

    for (final def in defaultCategories) {
      if (idsByName.containsKey(def.name)) continue;
      idsByName[def.name] = await into(categories).insert(
        CategoriesCompanion.insert(
          name: def.name,
          iconKey: def.iconKey,
          colorValue: def.colorValue,
          type: def.type,
          sortOrder: Value(def.sortOrder),
          isDefault: const Value(true),
        ),
      );
    }

    await batch((b) {
      for (final def in defaultCategories) {
        b.update(
          categories,
          CategoriesCompanion(sortOrder: Value(def.sortOrder)),
          where: (c) => c.id.equals(idsByName[def.name]!),
        );
      }
    });
  }

  /// Idempotente: si ya hay filas, no hace nada. Así reabrir la app no
  /// duplica el catálogo.
  Future<void> _seedCategories() async {
    final existing = await (select(categories)..limit(1)).get();
    if (existing.isNotEmpty) return;

    await batch((b) {
      b.insertAll(
        categories,
        defaultCategories
            .map(
              (c) => CategoriesCompanion.insert(
                name: c.name,
                iconKey: c.iconKey,
                colorValue: c.colorValue,
                type: c.type,
                sortOrder: Value(c.sortOrder),
                isDefault: const Value(true),
              ),
            )
            .toList(),
      );
    });
  }
}

/// Conexión real (§36). `drift_flutter` resuelve la ruta por plataforma,
/// incluido `path_provider`; no hace falta construirla a mano.
QueryExecutor _openConnection() => driftDatabase(name: 'pipe_finanzas');
