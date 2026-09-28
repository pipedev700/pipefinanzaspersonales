import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/presentation/providers/category_providers.dart';
import '../../../movements/domain/entities/movement.dart';
import '../../../movements/domain/financial_calculator.dart';
import '../../../movements/domain/financial_summary.dart';
import '../../../movements/domain/financial_values.dart';
import '../../../movements/presentation/providers/history_providers.dart';
import '../../../../core/providers/repository_providers.dart';

/// §13 — Resumen del mes: totales, balance, desglose y tasa de ahorro.
///
/// El mes del dashboard y el del historial comparten el **mismo** estado
/// (`selectedMonthProvider`), para que cambiar de pestaña no pierda el filtro.
///
/// El cálculo necesita el catálogo de categorías además de los movimientos:
/// sin él el desglose solo tendría el id, y no el nombre, el color ni el icono.
///
/// Lee [monthMovementsProvider] (sin filtrar) y no
/// [movementsForSelectedMonthProvider]: el filtro por categoría es un control
/// de las pantallas de Historial e Histórico, y el dashboard no tiene botón
/// para quitarlo. Mostrar aquí solo las categorías elegidas dejaría unas
/// cifras que nadie puede explicar a simple vista.
final monthlySummaryProvider = Provider<AsyncValue<FinancialSummary>>((ref) {
  final movements = ref.watch(monthMovementsProvider);
  final categories = ref.watch(categoriesProvider).value ?? const [];
  return movements.whenData((list) => FinancialSummary.from(list, categories));
});

/// Los 5 movimientos más recientes del mes.
///
/// Se apoya en el orden del DAO (`date DESC`), no en un `sort`: volver a
/// ordenar aquí sería trabajo redundante y una fuente más de desincronización.
/// Sin filtro por la misma razón que [monthlySummaryProvider].
final recentMovementsProvider = Provider<AsyncValue<List<Movement>>>((ref) {
  return ref
      .watch(monthMovementsProvider)
      .whenData((list) => list.take(5).toList(growable: false));
});

/// Categorías con gastos este mes, de mayor a menor.
///
/// Se lee directo de [monthlySummaryProvider] en vez de recalcular: el desglose
/// ya está en el resumen, y duplicar el cálculo haría que dos widgets pudieran
/// mostrar números distintos si algún día divergieran.
final breakdownProvider = Provider<AsyncValue<List<CategoryBreakdown>>>((ref) {
  return ref
      .watch(monthlySummaryProvider)
      .whenData((summary) => summary.byCategory);
});

/// Todos los movimientos, no solo los del mes visible. El gráfico de 6 meses
/// necesita la serie completa.
final allMovementsProvider = StreamProvider<List<Movement>>(
  (ref) => ref.watch(movementRepositoryProvider).watchAll(),
);

/// S07 — Últimos 6 meses para el gráfico de barras.
///
/// La ventana termina en el mes **seleccionado**, no en el mes actual: si se
/// retrocede a marzo, el gráfico debe enseñar febrero–marzo, no stretching
/// hasta hoy. Además `lastMonths` necesita un mes de referencia explícito, así
/// que sin esto el eje no tendría dónde anclarse.
final lastSixMonthsProvider = Provider<AsyncValue<List<MonthlyBar>>>((ref) {
  const calc = FinancialCalculator();
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(allMovementsProvider)
      .whenData((all) => calc.lastMonths(all, 6, month));
});

/// El último mes **con movimientos** de la ventana del gráfico, o `null` si en
/// esos seis meses no se registró nada.
///
/// Es lo que evita que el dashboard de un mes vacío sea solo el mensaje "Aún no
/// tienes movimientos": en vez de eso muestra cuánto se movió el dinero la
/// última vez que hubo actividad, y un toque lleva a ese mes.
///
/// Sale de [lastSixMonthsProvider] y no de una consulta propia porque la
/// ventana ya está cargada para el gráfico y [FinancialCalculator.lastMonths]
/// es quien decide qué meses caen dentro. Una segunda consulta repetiría el
/// rango del mes en otro sitio, que es justo la duplicación que después
/// diverge.
final lastMonthWithDataProvider = Provider<AsyncValue<MonthlyBar?>>((ref) {
  return ref.watch(lastSixMonthsProvider).whenData((bars) {
    // `reversed`: la ventana viene de más antiguo a más reciente, así que el
    // último con datos es el primero que aparece al recorrerla al revés.
    for (final bar in bars.reversed) {
      if (bar.income > 0 || bar.expense > 0) return bar;
    }
    return null;
  });
});
