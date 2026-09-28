import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/movement.dart';
import '../../domain/financial_calculator.dart';
import '../../domain/financial_values.dart';

/// Carga puntual de un movimiento, para el formulario de edición.
///
/// Aquí sí se usa `.family`, pero es un `FutureProvider` con argumento: Riverpod
/// sí entrega `int id` a `build`, así que no hace falta codegen ni
/// `FamilyNotifier` (que ya no existe en Riverpod 3, ver §6.1).
final movementByIdProvider = FutureProvider.family<Movement?, int>((ref, id) {
  return ref.watch(movementRepositoryProvider).getById(id);
});

/// Mes visible en el dashboard y el historial. El filtro mensual es la
/// única fuente de "qué mes estoy viendo" en toda la app (§D12).
///
/// No es `autoDispose` a propósito: al cambiar de pestaña el mes elegido se
/// conserva en lugar de saltar de vuelta al actual.
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// `DateTime` normaliza `month - 1` hacia el año anterior, así que enero
  /// retrocede a diciembre del año pasado sin casos especiales.
  void previous() => state = DateTime(state.year, state.month - 1);

  void next() {
    final now = DateTime.now();
    final candidate = DateTime(state.year, state.month + 1);
    // No se puede avanzar más allá del mes en curso.
    if (candidate.isAfter(DateTime(now.year, now.month))) return;
    state = candidate;
  }

  void goTo(DateTime month) => state = DateTime(month.year, month.month);
}

final selectedMonthProvider = NotifierProvider<SelectedMonth, DateTime>(
  SelectedMonth.new,
);

/// Si el filtro ya está en el mes en curso no hay a dónde avanzar. Lo consume
/// el botón `›` del historial para deshabilitarse, en vez de dejar que `next()`
/// descarte el toque en silencio.
final canAdvanceMonthProvider = Provider<bool>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final now = DateTime.now();
  return month.isBefore(DateTime(now.year, now.month));
});

/// Filtro de categorías del historial. Un conjunto de ids; **vacío = todas**.
///
/// No es `autoDispose`: al saltar a otra pestaña el filtro se conserva, igual
/// que el mes. Es un `Set` y no una `List` para que quitar y volver a poner la
/// misma categoría no la duplique, y para que `state` solo cambie cuando el
/// conjunto cambia de verdad.
class CategoryFilter extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void toggle(int id) {
    final next = Set<int>.of(state);
    if (!next.remove(id)) next.add(id);
    state = next;
  }

  /// Vacío = todas, así que "limpiar" y "todas" son la misma operación.
  void clear() => state = const {};
}

final historyCategoryFilterProvider =
    NotifierProvider<CategoryFilter, Set<int>>(CategoryFilter.new);

/// Aplica el filtro de [historyCategoryFilterProvider] a una lista ya traída
/// de la base.
///
/// El filtrado va **en Dart**, no en SQL, a propósito: el conjunto de ids
/// cambia con cada toque y meter un `IN (...)` variable en la consulta
/// reinicia el stream en cada pulsación. Los índices de `movements.category_id`
/// siguen sirviendo para el recorte por fecha, que es el que pesa.
List<Movement> applyCategoryFilter(
  List<Movement> movements,
  Set<int> categoryIds,
) {
  if (categoryIds.isEmpty) return movements;
  return movements
      .where((m) => categoryIds.contains(m.category.id))
      .toList(growable: false);
}

/// §13 — Movimientos del mes seleccionado, ordenados por el DAO. Los cálculos
/// se hacen en Dart, no en SQL.
///
/// **Este provider no sabe nada del filtro de categorías**, a propósito. Si el
/// `StreamProvider` dependiera del filtro, al cambiarlo Riverpod lo marcaría
/// como sucio; la siguiente pantalla que lo montara (la rama "Historial", que
/// solo se construye al abrir la pestaña) lo reconstruiría *dentro* de su
/// propio `build`, y la invalidación resultante intentaba repintar el
/// `ProviderScope` durante el build → aserción en tiempo de ejecución. Separar
/// el stream del filtrado deja la suscripción viva y, de paso, evita
/// resuscribirse a la base en cada pulsación de la casilla.
final monthMovementsProvider = StreamProvider<List<Movement>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(movementRepositoryProvider).watchByMonth(month);
});

/// Los movimientos del mes con el filtro de categorías aplicado.
///
/// Es un `Provider` y no un `StreamProvider` a propósito: el filtrado es una
/// transformación de datos que ya están en memoria, no una consulta nueva.
final movementsForSelectedMonthProvider = Provider<AsyncValue<List<Movement>>>((
  ref,
) {
  final movements = ref.watch(monthMovementsProvider);
  final categories = ref.watch(historyCategoryFilterProvider);
  return movements.whenData((list) => applyCategoryFilter(list, categories));
});

/// §13 — El historial agrupado por día, con subtotales.
///
/// El agrupado no reordena: el DAO ya entrega `date DESC`, así que los días
/// salen del más reciente al más antiguo. Escribir aquí un `sort` por fecha
/// Ascendente para "asegurarlo" rompería ese orden.
final historyGroupsProvider = Provider<AsyncValue<List<DailyGroup>>>((ref) {
  const calc = FinancialCalculator();
  return ref.watch(movementsForSelectedMonthProvider).whenData(calc.groupByDay);
});
