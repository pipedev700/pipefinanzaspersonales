import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../categories/presentation/widgets/category_icon.dart';
import '../../../movements/domain/entities/category.dart';

/// §12 — Grid de categorías ya filtradas por tipo. Objeto seleccionable único:
/// no hay modo multiple, porque un movimiento pertenece a una sola categoría.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    super.key,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'No hay categorías de este tipo',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        // 4 columnas, no 3: con 10 categorías de gasto, 3 columnas son 4
        // filas y el formulario no cabe en la pantalla del móvil. Con 4 son
        // 3 filas y entra entero.
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        // A 360px de ancho la celda sale de 76px: el alto acompaña para
        // guardar el icono y su etiqueta sin quedarlos pegados al borde.
        childAspectRatio: 1.05,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final selected = category.id == selectedId;
        final color = Color(category.colorValue);

        return Semantics(
          selected: selected,
          button: true,
          label: category.name,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: () => onChanged(category.id),
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.12)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: selected ? color : theme.dividerColor,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CategoryIcon(category: category, size: _iconSize),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        // El color va explícito: `labelSmall` no lo
                        // declara, y sin esto el nombre se quedaba con
                        // `color: null` y lo resolvía el ambiente.
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: _labelSize,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Icono de 36 a 28 al compactar la rejilla. El objetivo táctil real es la
  /// celda completa, no el círculo, así que sigue muy por encima del mínimo
  /// de §35.
  static const _iconSize = 28.0;
  static const _labelSize = 10.0;
}
