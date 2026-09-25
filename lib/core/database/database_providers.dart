import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos.dart';

/// La base de datos se crea al primer uso y se cierra al destruirse el
/// ProviderScope. No es `autoDispose`: la app la usa en todo momento.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final movementsDaoProvider = Provider<MovementsDao>(
  (ref) => MovementsDao(ref.watch(appDatabaseProvider)),
);

final categoriesDaoProvider = Provider<CategoriesDao>(
  (ref) => CategoriesDao(ref.watch(appDatabaseProvider)),
);
