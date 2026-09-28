import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/theme_mode_button.dart';
import '../../../movements/domain/financial_values.dart';
import '../../../movements/presentation/providers/history_providers.dart';
import '../../../movements/presentation/widgets/category_filter_sheet.dart';
import '../../../movements/presentation/widgets/day_header.dart';
import '../../../movements/presentation/widgets/movement_tile.dart';
import '../../providers/historical_providers.dart';

/// Histórico — consulta por rango de fechas y categorías.
///
/// Es la tercera pestaña y no una pantalla suelta: el filtro de categorías es
/// **el mismo** que el del historial ([historyCategoryFilterProvider]), así que
/// lo que el usuario marca en una pantalla también vale en la otra. Duplicar
/// el estado haría que "limpiar" en un sitio dejara el otro filtrado sin avisar.
class HistoricalScreen extends ConsumerWidget {
  const HistoricalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(rangeGroupsProvider);
    final totals = ref.watch(rangeTotalsProvider);
    final range = ref.watch(historyRangeProvider);
    final filtered = ref.watch(historyCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: filtered.isEmpty
                ? 'Filtrar por categoría'
                : 'Filtrar por categoría (${filtered.length} activas)',
            icon: Badge(
              isLabelVisible: filtered.isNotEmpty,
              label: Text('${filtered.length}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => CategoryFilterSheet.show(context),
          ),
          const ThemeModeButton(),
        ],
      ),
      body: Column(
        children: [
          _RangeBar(range: range),
          _TotalsCard(totals: totals),
          const Divider(height: 1),
          Expanded(
            child: groups.when(
              data: (days) => days.isEmpty
                  ? _empty(context, filtered.isNotEmpty)
                  : _list(days),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  'No se pudo cargar el histórico',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ListView _list(List<DailyGroup> days) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: days.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: AppSpacing.md),
      itemBuilder: (context, i) {
        final group = days[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayHeader(group: group),
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

  Widget _empty(BuildContext context, bool filtered) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.4,
          child: EmptyState(
            icon: Icons.search_off_outlined,
            title: 'Sin resultados',
            message: filtered
                ? 'No hay movimientos de las categorías elegidas en ese rango.'
                : 'No hay movimientos registrados en ese rango de fechas.',
          ),
        ),
      ],
    );
  }
}

/// Fila con los dos extremos del rango y los botones para cambiarlos.
class _RangeBar extends ConsumerWidget {
  const _RangeBar({required this.range});

  final HistoryRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(historyRangeProvider.notifier);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Desde',
                  value: range.start,
                  firstDate: DateTime(today.year - 5),
                  lastDate: today,
                  onPicked: notifier.setStart,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: _DateButton(
                  label: 'Hasta',
                  value: range.end,
                  firstDate: DateTime(today.year - 5),
                  lastDate: today,
                  onPicked: notifier.setEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${range.days} día${range.days == 1 ? '' : 's'} · '
                  '${formatRange(range)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: notifier.reset,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Restablecer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
  });

  final String label;
  final DateTime value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _clamp(value),
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: 'Selecciona $label',
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            AppDateUtils.formatShort(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// `showDatePicker` lanza una aserción si `initialDate` se sale de
  /// `[firstDate, lastDate]`. El rango vive en el provider y sobrevive a los
  /// cambios de fecha del dispositivo, así que se clampa en vez de confiar.
  DateTime _clamp(DateTime value) {
    if (value.isBefore(firstDate)) return firstDate;
    if (value.isAfter(lastDate)) return lastDate;
    return value;
  }
}

/// Resumen del rango: balance, ingresos y gastos.
///
/// El balance se pinta con su signo y su color semántico. Es el mismo criterio
/// que [DayHeader]: el signo lo da el tipo del movimiento, y un rango que
/// cerró en positivo nunca se muestra en rojo.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final AsyncValue<({int income, int expense, int balance})> totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: totals.when(
        loading: () => const SizedBox(
          height: 64,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (t) {
          final isPositive = t.balance >= 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance del rango',
                style: AppTypography.label.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                label: 'Balance del rango',
                value:
                    '${isPositive ? 'Positivo' : 'Negativo'}, '
                    '${CurrencyFormatter.cop.formatSigned(t.balance)}',
                child: Text(
                  CurrencyFormatter.cop.formatSigned(t.balance),
                  style: AppTypography.display.copyWith(
                    color: isPositive ? semantic.income : semantic.expense,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _TotalCell(
                      label: 'Ingresos',
                      amount: t.income,
                      color: semantic.income,
                    ),
                  ),
                  Expanded(
                    child: _TotalCell(
                      label: 'Gastos',
                      amount: t.expense,
                      color: semantic.expense,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          CurrencyFormatter.cop.format(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyStrong.copyWith(color: color),
        ),
      ],
    );
  }
}
