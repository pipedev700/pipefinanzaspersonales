import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/theme_mode_button.dart';
import '../../domain/financial_values.dart';
import '../providers/history_providers.dart';
import '../widgets/category_filter_sheet.dart';
import '../widgets/day_header.dart';
import '../widgets/movement_tile.dart';

/// §13 — Historial del mes, agrupado por día con subtotales.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(historyGroupsProvider);
    final month = ref.watch(selectedMonthProvider);
    final canAdvance = ref.watch(canAdvanceMonthProvider);
    final filtered = ref.watch(historyCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        // El selector de mes vive en el cuerpo, no aquí. Con las flechas, el
        // mes pulsable y el botón de tema en el AppBar, las acciones sumaban
        // 377px en una barra de 360: el título y la última acción se
        // salían de la pantalla. No se notaba en los tests porque usaban una
        // superficie de 1000px de ancho.
        actions: [
          _FilterButton(count: filtered.length),
          const ThemeModeButton(),
        ],
      ),
      body: Column(
        children: [
          _monthSelector(context, ref, month, canAdvance),
          if (filtered.isNotEmpty) _ActiveFilterBar(count: filtered.length),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(monthMovementsProvider);
              },
              child: groups.when(
                data: (days) => days.isEmpty
                    ? _empty(context, month, filtered.isNotEmpty)
                    : _list(days),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'No se pudo cargar el historial',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `‹ mes ›` con el mes pulsable para abrir el selector de fecha. Es la fila
  /// que antes estaba en el AppBar.
  Widget _monthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
    bool canAdvance,
  ) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(selectedMonthProvider.notifier).previous(),
        ),
        Expanded(
          child: Center(
            child: TextButton(
              onPressed: () => _showMonthPicker(context, ref, month),
              child: Text(
                AppDateUtils.formatMonth(month),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
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

  /// El `ListView` con `AlwaysScrollableScrollPhysics` es lo que permite tirar
  /// hacia abajo en un mes vacío: si no, el `RefreshIndicator` nunca recibe el
  /// gesto.
  Widget _empty(BuildContext context, DateTime month, bool filtered) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Sin movimientos',
            message: filtered
                ? 'No hay movimientos de las categorías elegidas en '
                      '${AppDateUtils.formatMonthRelative(month, DateTime.now())}.'
                : '${AppDateUtils.formatMonthRelative(month, DateTime.now())} '
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

/// Botón del AppBar que abre el selector de categorías. Muestra cuántas hay
/// activas para que el filtro sea visible sin abrir la hoja.
class _FilterButton extends ConsumerWidget {
  const _FilterButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = count > 0;
    return IconButton(
      tooltip: active
          ? 'Filtrar por categoría ($count activas)'
          : 'Filtrar por categoría',
      icon: Badge(
        isLabelVisible: active,
        label: Text('$count'),
        child: const Icon(Icons.filter_list),
      ),
      onPressed: () async {
        final changed = await CategoryFilterSheet.show(context);
        if (changed == true && context.mounted) {
          showAppSnackBar(
            context,
            'Filtrando por $count categoría${count == 1 ? '' : 's'}',
            SnackBarKind.info,
          );
        }
      },
    );
  }
}

/// Aviso de que hay un filtro puesto, con la forma de quitarlo sin abrir la
/// hoja. Sin esto el usuario ve una lista más corta y no sabe por qué.
class _ActiveFilterBar extends ConsumerWidget {
  const _ActiveFilterBar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '$count categoría${count == 1 ? '' : 's'} seleccionada'
              '${count == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(historyCategoryFilterProvider.notifier).clear(),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}
