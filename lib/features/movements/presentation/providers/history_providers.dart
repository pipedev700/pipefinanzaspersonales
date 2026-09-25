import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/movement.dart';

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

final selectedMonthProvider =
    NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);

/// §13 — Movimientos del mes seleccionado, ya filtrados y ordenados por el
/// DAO. Los cálculos se hacen en Dart, no en SQL.
final movementsForSelectedMonthProvider = StreamProvider<List<Movement>>((
  ref,
) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(movementRepositoryProvider).watchByMonth(month);
});
