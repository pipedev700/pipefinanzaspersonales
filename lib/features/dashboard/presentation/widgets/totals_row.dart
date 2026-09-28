import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';

/// §13 — Tarjetas de ingresos y gastos, lado a lado.
class TotalsRow extends StatelessWidget {
  const TotalsRow({required this.income, required this.expense, super.key});

  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TotalCard(
            label: 'Ingresos',
            amount: income,
            icon: Icons.trending_up,
            color: context.semantic.income,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TotalCard(
            label: 'Gastos',
            amount: expense,
            icon: Icons.trending_down,
            color: context.semantic.expense,
          ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                // Sin `Expanded`: un `Row` dentro de una `Column` se ajusta al
                // ancho disponible, pero si la etiqueta se puso aWrapear
                // borraría el ícono.
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              CurrencyFormatter.cop.format(amount),
              style: AppTypography.title.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
