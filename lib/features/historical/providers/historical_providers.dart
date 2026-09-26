import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../movements/domain/entities/movement.dart';
import '../../movements/domain/financial_calculator.dart';
import '../../movements/domain/financial_values.dart';
import '../../movements/presentation/providers/history_providers.dart';

/// Rango de fechas de la pantalla de histórico, cerrado por los dos extremos.
///
/// A diferencia de [SelectedMonth] aquí el rango lo elige el usuario, así que
/// el estado guarda los dos días tal cual, no un mes. El valor por defecto
/// son los últimos 90 días: un rango que se sale de la pantalla no sirve de
/// nada, y 3 meses es lo que una persona revisa de verdad.
class HistoryRange {
  const HistoryRange({required this.start, required this.end});

  /// Primer día incluido, a medianoche local.
  final DateTime start;

  /// Último día **incluido**, a medianoche local. El DAO recibe el día
  /// siguiente porque su rango es `[start, end)`.
  final DateTime end;

  /// Lo que se le pasa a `watchByRange`: el día después del último.
  DateTime get exclusiveEnd => DateTime(end.year, end.month, end.day + 1);

  int get days => end.difference(start).inDays + 1;

  HistoryRange copyWith({DateTime? start, DateTime? end}) =>
      HistoryRange(start: start ?? this.start, end: end ?? this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryRange &&
          other.start.year == start.year &&
          other.start.month == start.month &&
          other.start.day == start.day &&
          other.end.year == end.year &&
          other.end.month == end.month &&
          other.end.day == end.day);

  /// Debe derivationar de los **mismos** campos que [==]. Hashear los
  /// `DateTime` enteros hacía que dos rangos iguales (mismo día, distinta hora)
  /// tuvieran hash distinto, y eso rompe cualquier `Set` o `Map` que los use.
  @override
  int get hashCode => Object.hash(_day(start), _day(end));

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

final historyRangeProvider =
    NotifierProvider<_HistoryRangeBuilder, HistoryRange>(
      _HistoryRangeBuilder.new,
    );

/// Últimos 90 días, el punto de partida de la pantalla.
HistoryRange defaultHistoryRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return HistoryRange(
    start: DateTime(today.year, today.month, today.day - 89),
    end: today,
  );
}

class _HistoryRangeBuilder extends Notifier<HistoryRange> {
  @override
  HistoryRange build() => defaultHistoryRange();

  /// Aplica el rango. Si el usuario deja el inicio después del fin se
  /// corrige en vez de mostrar una lista vacía sin explicación: `DatePicker`
  /// permite elegir cualquier orden y es un tropiezo fácil.
  void set(DateTime start, DateTime end) {
    final a = _day(start);
    final b = _day(end);
    state = a.isAfter(b)
        ? HistoryRange(start: b, end: a)
        : HistoryRange(start: a, end: b);
  }

  void setStart(DateTime value) => set(value, state.end);

  void setEnd(DateTime value) => set(state.start, value);

  void reset() => state = defaultHistoryRange();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Rango de fechas legible para el botón que lo abre.
String formatRange(HistoryRange range) {
  final desde = '${range.start.day}/${range.start.month}/${range.start.year}';
  final hasta = '${range.end.day}/${range.end.month}/${range.end.year}';
  return '$desde – $hasta';
}

/// Movimientos del rango, sin filtrar.
///
/// Igual que [monthMovementsProvider] en el historial: el stream no depende del
/// filtro de categorías, y el filtrado se hace en el provider de abajo. Si
/// estuvieran en el mismo, cambiar el filtro invalidaría el stream y esa
/// invalidación caería dentro del `build` de la rama que se está montando.
final rangeMovementsStreamProvider = StreamProvider<List<Movement>>((ref) {
  final range = ref.watch(historyRangeProvider);
  return ref
      .watch(movementRepositoryProvider)
      .watchByRange(range.start, range.exclusiveEnd);
});

/// Los movimientos del rango, con el filtro de categorías del historial
/// aplicado.
///
/// Reutiliza [historyCategoryFilterProvider] a propósito: el filtro es la misma
/// decisión del usuario en las dos pantallas, y tenerlos separados haría que
/// limpiar uno dejara el otro filtrado sin avisar.
final rangeMovementsProvider = Provider<AsyncValue<List<Movement>>>((ref) {
  final movements = ref.watch(rangeMovementsStreamProvider);
  final categories = ref.watch(historyCategoryFilterProvider);
  return movements.whenData((list) => applyCategoryFilter(list, categories));
});

/// Los mismos movimientos, agrupados por día.
final rangeGroupsProvider = Provider<AsyncValue<List<DailyGroup>>>((ref) {
  const calc = FinancialCalculator();
  return ref.watch(rangeMovementsProvider).whenData(calc.groupByDay);
});

/// Totales de todo el rango, para el resumen de arriba de la pantalla.
final rangeTotalsProvider =
    Provider<AsyncValue<({int income, int expense, int balance})>>((ref) {
      const calc = FinancialCalculator();
      return ref
          .watch(rangeMovementsProvider)
          .whenData(
            (movements) => (
              income: calc.totalIncome(movements),
              expense: calc.totalExpense(movements),
              balance: calc.balance(movements),
            ),
          );
    });
