import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/presentation/category_icon_registry.dart';
import '../../../movements/domain/financial_values.dart';

/// §13 — Barra de progreso por categoría, ordenada de mayor a menor.
class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({required this.items, super.key});

  final List<CategoryBreakdown> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por categoría',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final b in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          CategoryIconRegistry.resolve(b.iconKey),
                          size: 16,
                          color: Color(b.colorValue),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            b.categoryName,
                            style: AppTypography.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.cop.format(b.amount)}  '
                          '${b.percentage.toStringAsFixed(1)}%',
                          style: AppTypography.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        // 0..1 porque `LinearProgressIndicator` espera una
                        // fracción, no un porcentaje. El `clamp` protege de
                        // un redondeo a 100,1 % si algún día los porcentajes no
                        // dan exactamente 100.
                        value: (b.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(Color(b.colorValue)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
