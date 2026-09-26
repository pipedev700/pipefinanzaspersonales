import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/theme_mode_button.dart';
import '../../../movements/domain/entities/movement.dart';
import '../../../movements/domain/financial_summary.dart';
import '../../../movements/domain/financial_values.dart';
import '../../../movements/presentation/providers/history_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/last_month_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/monthly_bars.dart';
import '../widgets/recent_movements.dart';
import '../widgets/totals_row.dart';

/// §13 — Pantalla de inicio. Es la primera pestaña del shell.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final recent = ref.watch(recentMovementsProvider);
    final breakdown = ref.watch(breakdownProvider);
    final bars = ref.watch(lastSixMonthsProvider);
    final lastMonth = ref.watch(lastMonthWithDataProvider);
    // Provider y no `notifier.canGoNext` leído en el `build`: leer el notifier
    // no es reactivo, así que el botón seguiría habilitado tras cambiar de
    // mes desde el historial.
    final canAdvance = ref.watch(canAdvanceMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipe Finanzas'),
        actions: const [ThemeModeButton()],
      ),
      body: summary.when(
        data: (s) {
          // "Sin movimientos" se decide por el conteo, no por si el balance es
          // cero: un mes con un gasto y un ingreso del mismo valor tiene
          // balance 0 y **sí** tiene datos que mostrar.
          final vacio = s.transactionCount == 0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(monthlySummaryProvider);
              ref.invalidate(recentMovementsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                96,
              ),
              children: [
                // El selector va **siempre**, también en un mes vacío. Antes
                // solo se pintaba con datos, así que al caer en un mes sin
                // movimientos desaparecían las flechas y la pantalla quedaba
                // con un mensaje y sin forma de volver: quien acababa de
                // registrar el mes en curso veía "Aún no tienes movimientos"
                // sin poder llegar a él.
                MonthSelector(
                  month: month,
                  onPrevious: () =>
                      ref.read(selectedMonthProvider.notifier).previous(),
                  onNext: canAdvance
                      ? () => ref.read(selectedMonthProvider.notifier).next()
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (vacio)
                  ..._vacio(ref, month, bars, lastMonth)
                else
                  ..._conDatos(s, month, recent, breakdown, bars),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'No se pudo cargar el resumen',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }

  /// El mes visible no tiene movimientos.
  ///
  /// No se queda en el mensaje: debajo va el resumen del último mes que sí
  /// tuvo actividad, para que la pantalla diga si la app está vacía de verdad o
  /// lo que falta son datos de este mes, y para tener a mano un salto a ese
  /// mes. Arriba, el "ver el mes actual" rescata a quien quedó en un mes
  /// pasado sin haberlo buscado.
  List<Widget> _vacio(
    WidgetRef ref,
    DateTime month,
    AsyncValue<List<MonthlyBar>> bars,
    AsyncValue<MonthlyBar?> lastMonth,
  ) {
    final now = DateTime.now();
    final mesActual = DateTime(now.year, now.month);
    // La guarda del mes distinto es defensiva: la ventana del gráfico
    // termina en el mes visible, así que el último mes con datos nunca es
    // este. Si algún día la ventana se abriera más, sin la guarda se
    // rotularía "Resumen de septiembre" en un septiembre vacío.
    final anterior = lastMonth.value;

    return [
      SizedBox(
        height: 240,
        child: EmptyState(
          icon: Icons.pie_chart_outline,
          title: AppDateUtils.formatMonthRelative(month, now),
          message:
              'Aún no tienes movimientos. Registra tu primer ingreso o gasto '
              'para ver tu resumen.',
        ),
      ),
      if (!month.isAtSameMomentAs(mesActual)) ...[
        Center(
          child: TextButton(
            onPressed: () =>
                ref.read(selectedMonthProvider.notifier).goTo(mesActual),
            child: const Text('Ver el mes actual'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (anterior != null && !anterior.month.isAtSameMomentAs(month)) ...[
        LastMonthCard(
          month: anterior.month,
          income: anterior.income,
          expense: anterior.expense,
          onTap: () => ref
              .read(selectedMonthProvider.notifier)
              .goTo(anterior.month),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      // El gráfico también entra en el mes vacío: la ventana de seis meses
      // sigue teniendo datos que comparar y es lo que deja ver de un vistazo
      // que la actividad de meses anteriores sigue ahí.
      if (bars.value?.isNotEmpty ?? false) ...[
        MonthlyBars(bars: bars.value!),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  /// El mes visible tiene movimientos: el panel completo de siempre.
  List<Widget> _conDatos(
    FinancialSummary s,
    DateTime month,
    AsyncValue<List<Movement>> recent,
    AsyncValue<List<CategoryBreakdown>> breakdown,
    AsyncValue<List<MonthlyBar>> bars,
  ) {
    return [
      BalanceCard(balance: s.balance, month: month, savingsRate: s.savingsRate),
      const SizedBox(height: AppSpacing.md),
      TotalsRow(income: s.totalIncome, expense: s.totalExpense),
      const SizedBox(height: AppSpacing.md),
      if (bars.value?.isNotEmpty ?? false) ...[
        MonthlyBars(bars: bars.value!),
        const SizedBox(height: AppSpacing.md),
      ],
      // `value` en vez de `maybeWhen`: dentro de `data:` del resumen estos dos
      // ya están resueltos, y un `orElse: shrink()` escondería también un error
      // de la consulta de categorías.
      if (breakdown.value?.isNotEmpty ?? false) ...[
        CategoryBreakdownList(items: breakdown.value!),
        const SizedBox(height: AppSpacing.md),
      ],
      if (recent.value?.isNotEmpty ?? false)
        RecentMovements(movements: recent.value!),
    ];
  }
}
