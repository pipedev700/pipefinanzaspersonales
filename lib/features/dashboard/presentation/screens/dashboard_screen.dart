import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../movements/presentation/providers/history_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/month_selector.dart';
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
    // Provider y no `notifier.canGoNext` leído en el `build`: leer el notifier
    // no es reactivo, así que el botón seguiría habilitado tras cambiar de
    // mes desde el historial.
    final canAdvance = ref.watch(canAdvanceMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pipe Finanzas')),
      body: summary.when(
        data: (s) {
          // "Sin movimientos" se decide por el conteo, no por si el balance es
          // cero: un mes con un gasto y un ingreso del mismo valor tiene
          // balance 0 y **sí** tiene datos que mostrar.
          if (s.transactionCount == 0) {
            return _empty(context, month);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(monthlySummaryProvider);
              ref.invalidate(recentMovementsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                96,
              ),
              children: [
                MonthSelector(
                  month: month,
                  onPrevious: () =>
                      ref.read(selectedMonthProvider.notifier).previous(),
                  onNext: canAdvance
                      ? () => ref.read(selectedMonthProvider.notifier).next()
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                BalanceCard(
                  balance: s.balance,
                  month: month,
                  savingsRate: s.savingsRate,
                ),
                const SizedBox(height: AppSpacing.md),
                TotalsRow(income: s.totalIncome, expense: s.totalExpense),
                const SizedBox(height: AppSpacing.md),
                // `value` en vez de `maybeWhen`: dentro de `data:` del resumen
                // estos dos ya están resueltos, y un `orElse: shrink()`
                // escondería también un error de la consulta de categorías.
                if (breakdown.value?.isNotEmpty ?? false) ...[
                  CategoryBreakdownList(items: breakdown.value!),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (recent.value?.isNotEmpty ?? false)
                  RecentMovements(movements: recent.value!),
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

  /// El `ListView` con `AlwaysScrollableScrollPhysics` es lo que permite tirar
  /// hacia abajo en un mes vacío, igual que en el historial.
  Widget _empty(BuildContext context, DateTime month) {
    final relative = AppDateUtils.formatMonthRelative(month, DateTime.now());
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: EmptyState(
            icon: Icons.pie_chart_outline,
            title: relative,
            message:
                'Aún no tienes movimientos. Registra tu primer ingreso o gasto '
                'para ver tu resumen.',
          ),
        ),
      ],
    );
  }
}
