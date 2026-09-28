import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_icon.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/movement_type.dart';
import '../providers/history_providers.dart';

/// Bottom sheet con el catálogo completo en dos grupos (gastos e ingresos) y
/// una casilla por categoría.
///
/// El filtro vive en [historyCategoryFilterProvider], no en el sheet: así la
/// lista de detrás se va filtrando **mientras** se elige, que es lo que hace
/// útil un filtro en vez de tener que confirmar a ciegas.
///
/// Devuelve `true` si al cerrar había filtro, para que la pantalla pueda
/// confirmarlo con un `SnackBar`.
class CategoryFilterSheet extends ConsumerWidget {
  const CategoryFilterSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CategoryFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final selected = ref.watch(historyCategoryFilterProvider);
    final notifier = ref.read(historyCategoryFilterProvider.notifier);

    final expenses = all.where((c) => c.type.isExpense).toList(growable: false);
    final incomes = all.where((c) => c.type.isIncome).toList(growable: false);

    return SafeArea(
      child: ConstrainedBox(
        // Con 16 categorías el sheet no cabe entero en un móvil: se limita a
        // un 75% y el `ListView` deja el resto accesible.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrar por categoría',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: notifier.clear,
                      child: const Text('Limpiar'),
                    ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        Navigator.of(context).pop(selected.isNotEmpty),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                children: [
                  Text(
                    selected.isEmpty
                        ? 'Mostrando todas las categorías'
                        : 'Mostrando ${selected.length} '
                              'categoría${selected.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (expenses.isNotEmpty) ...[
                    _GroupTitle(
                      label: MovementType.expense.label,
                      color: context.semantic.expense,
                    ),
                    for (final c in expenses)
                      _CategoryTile(
                        category: c,
                        selected: selected.contains(c.id),
                        onTap: () => notifier.toggle(c.id),
                      ),
                  ],
                  if (incomes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _GroupTitle(
                      label: MovementType.income.label,
                      color: context.semantic.income,
                    ),
                    for (final c in incomes)
                      _CategoryTile(
                        category: c,
                        selected: selected.contains(c.id),
                        onTap: () => notifier.toggle(c.id),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(selected.isNotEmpty),
                  child: Text(
                    selected.isEmpty
                        ? 'Ver todas'
                        : 'Ver ${selected.length} '
                              'categoría${selected.length == 1 ? '' : 's'}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onTap(),
      dense: true,
      // `dense` + `contentPadding: EdgeInsets.zero` para que las 16 filas quepan
      // en el sheet sin obligar a hacer scroll.
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      secondary: CategoryIcon(category: category, size: 28),
      title: Text(category.name),
      activeColor: Color(category.colorValue),
    );
  }
}
