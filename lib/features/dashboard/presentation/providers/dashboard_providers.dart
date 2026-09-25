import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/presentation/providers/category_providers.dart';
import '../../../movements/domain/entities/movement.dart';
import '../../../movements/domain/financial_summary.dart';
import '../../../movements/domain/financial_values.dart';
import '../../../movements/presentation/providers/history_providers.dart';

/// §13 — Resumen del mes: totales, balance, desglose y tasa de ahorro.
///
/// El mes del dashboard y el del historial comparten el **mismo** estado
/// (`selectedMonthProvider`), para que cambiar de pestaña no pierda el filtro.
///
/// El cálculo necesita el catálogo de categorías además de los movimientos:
/// sin él el desglose solo tendría el id, y no el nombre, el color ni el icono.
final monthlySummaryProvider = Provider<AsyncValue<FinancialSummary>>((ref) {
  final movements = ref.watch(movementsForSelectedMonthProvider);
  final categories = ref.watch(categoriesProvider).value ?? const [];
  return movements.whenData(
    (list) => FinancialSummary.from(list, categories),
  );
});

/// Los 5 movimientos más recientes del mes.
///
/// Se apoya en el orden del DAO (`date DESC`), no en un `sort`: volver a
/// ordenar aquí sería trabajo redundante y una fuente más de desincronización.
final recentMovementsProvider = Provider<AsyncValue<List<Movement>>>((ref) {
  return ref.watch(
    movementsForSelectedMonthProvider,
  ).whenData((list) => list.take(5).toList(growable: false));
});

/// Categorías con gastos este mes, de mayor a menor.
///
/// Se lee directo de [monthlySummaryProvider] en vez de recalcular: el desglose
/// ya está en el resumen, y duplicar el cálculo haría que dos widgets pudieran
/// mostrar números distintos si algún día divergieran.
final breakdownProvider = Provider<AsyncValue<List<CategoryBreakdown>>>((ref) {
  return ref.watch(
    monthlySummaryProvider,
  ).whenData((summary) => summary.byCategory);
});
