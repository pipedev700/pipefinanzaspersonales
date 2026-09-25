import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../features/categories/data/drift_category_repository.dart';
import '../../../features/categories/domain/repositories/category_repository.dart';
import '../../../features/movements/data/drift_movement_repository.dart';
import '../../../features/movements/domain/repositories/movement_repository.dart';

/// La capa `presentation` depende de estas interfaces, nunca de `data`
/// ni de Drift (§27).
final movementRepositoryProvider = Provider<MovementRepository>(
  (ref) => DriftMovementRepository(ref.watch(movementsDaoProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(categoriesDaoProvider)),
);
