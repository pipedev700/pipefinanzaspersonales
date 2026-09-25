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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
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
