import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../categories/presentation/widgets/category_icon.dart';
import '../../domain/entities/movement.dart';

/// §12 — Fila: ícono, categoría + descripción, monto con signo.
class MovementTile extends StatelessWidget {
  const MovementTile({required this.movement, required this.onTap, super.key});

  final Movement movement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isIncome = movement.isIncome;
    final color = isIncome ? semantic.income : semantic.expense;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CategoryIcon(category: movement.category),
      // Sin descripción se muestra el nombre de la categoría como título: un
      // movimiento de "Supermercado" con la descripción vacía no puede quedarse
      // sin texto en la fila.
      title: Text(
        movement.description.isEmpty
            ? movement.category.name
            : movement.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        // Con descripción, el subtítulo repite la categoría; sin ella, repetir
        // el título sería ruido, así que se muestra solo la fecha y la hora.
        movement.description.isEmpty
            ? AppDateUtils.formatShortWithTime(movement.date)
            : '${movement.category.name} · ${AppDateUtils.formatShortWithTime(movement.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${CurrencyFormatter.cop.format(movement.amount)}',
        style: AppTypography.bodyStrong.copyWith(color: color),
      ),
    );
  }
}
