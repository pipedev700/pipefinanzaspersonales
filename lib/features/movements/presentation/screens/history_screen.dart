import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/financial_values.dart';
import '../providers/history_providers.dart';
import '../widgets/movement_tile.dart';

/// §13 — Historial del mes, agrupado por día con subtotales.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(historyGroupsProvider);
    final month = ref.watch(selectedMonthProvider);
    final canAdvance = ref.watch(canAdvanceMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                ref.read(selectedMonthProvider.notifier).previous(),
          ),
          TextButton(
            onPressed: () => _showMonthPicker(context, ref, month),            child: Text(AppDateUtils.formatMonth(month)),
          ),
          IconButton(
            // Deshabilitado en el mes en curso: `next()` ya ignoraría el
            // toque, pero un botón que no reacciona parece roto.
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: canAdvance
                ? () => ref.read(selectedMonthProvider.notifier).next()
                : null,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(historyGroupsProvider);
          ref.invalidate(movementsForSelectedMonthProvider);
        },
        child: groups.when(
          data: (days) => days.isEmpty ? _empty(context, month) : _list(days),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'No se pudo cargar el historial',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(List<DailyGroup> days) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: days.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: AppSpacing.md),
      itemBuilder: (context, i) {
        final group = days[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DayHeader(group: group),
            for (final m in group.movements)
              MovementTile(
                movement: m,
                onTap: () =>
                    context.push(AppRoutes.editMovementPath(m.id.toString())),
              ),
          ],
        );
      },
    );
  }

  /// El `ListView` con `AlwaysScrollableScrollPhysics` es lo que permite tirar
  /// hacia abajo en un mes vacío: si no, el `RefreshIndicator` nunca recibe el
  /// gesto.
  Widget _empty(BuildContext context, DateTime month) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Sin movimientos',
            message:
                '${AppDateUtils.formatMonthRelative(month, DateTime.now())} '
                'no tiene movimientos registrados.',
            actionLabel: 'Registrar movimiento',
            onAction: () => context.push(AppRoutes.newMovement),
          ),
        ),
      ],
    );
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year, now.month, now.day);
    // `initialDate` tiene que caer dentro del rango. El mes en curso empieza
    // el día 1, siempre anterior o igual a hoy, pero se clampa igual para que
    // el diálogo no lance la aserción si `current` se sale del rango.
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(firstDate) || current.isAfter(lastDate)
          ? lastDate
          : current,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecciona el mes',
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).goTo(picked);
    }
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.group});

  final DailyGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppDateUtils.formatShort(group.date),
              style: AppTypography.label.copyWith(
                // Sin este color el encabezado queda con `color: null` y lo
                // resuelve el ambiente: salía blanco sobre `surface`, igual
                // que le pasaba al monto y al nombre de las categorías.
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (group.totalExpense > 0)
            Text(
              '-${CurrencyFormatter.cop.format(group.totalExpense)}',
              style: AppTypography.label.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}
