import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';

/// §13 — Tarjeta principal: balance del mes con color semántico.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.balance,
    required this.month,
    required this.savingsRate,
    super.key,
  });

  final int balance;
  final DateTime month;

  /// `null` cuando no hubo ingresos: la tasa de ahorro sería división entre
  /// cero, así que no se pinta nada en vez de un `NaN` o un `Infinity`.
  final double? savingsRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isPositive = balance >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance · ${AppDateUtils.formatMonth(month)}',
              style: AppTypography.label.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // §35 — El color solo no se anuncia: un lector de pantalla tiene
            // que oír el valor con su signo, que es lo que distingue un
            // ingreso de un gasto.
            Semantics(
              label: 'Balance del mes',
              value:
                  '${isPositive ? 'Positivo' : 'Negativo'}, '
                  '${CurrencyFormatter.cop.formatSigned(balance)}',
              child: Text(
                CurrencyFormatter.cop.formatSigned(balance),
                style: AppTypography.display.copyWith(
                  color: isPositive ? semantic.income : semantic.expense,
                ),
              ),
            ),
            // Se muestra también en negativo: si el balance ya está en rojo,
            // callar la tasa de ahorro esconde justo el dato que explica por
            // qué. Solo se omite cuando no es calculable.
            if (savingsRate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ahorro: ${savingsRate!.toStringAsFixed(1)}% de tus ingresos',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
