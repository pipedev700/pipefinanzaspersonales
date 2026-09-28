import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';

/// Resumen del último mes en el que sí hubo movimientos.
///
/// Aparece **debajo** del estado vacío del mes que se está viendo. Sin esto un
/// mes sin datos deja la pantalla con un solo mensaje, y el usuario no sabe si
/// la app está vacía de verdad o si él está mirando el mes equivocado: el
/// resumen le dice las dos cosas a la vez.
///
/// Es pulsable y lleva a ese mes, que es lo que resuelve el caso de verdad:
/// estar en un mes vacío y no tener forma de volver al anterior.
class LastMonthCard extends StatelessWidget {
  const LastMonthCard({
    required this.month,
    required this.income,
    required this.expense,
    required this.onTap,
    super.key,
  });

  final DateTime month;
  final int income;
  final int expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final balance = income - expense;
    final isPositive = balance >= 0;
    final label = AppDateUtils.formatMonth(month);

    return Card(
      // `InkWell` y no `Material`: la `Card` ya pinta el fondo y el borde, y
      // envolverla en otro `Material` taparía ese borde con el color del
      // ripple.
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSpacing.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resumen de $label',
                      style: AppTypography.label.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                CurrencyFormatter.cop.formatSigned(balance),
                style: AppTypography.title.copyWith(
                  color: isPositive ? semantic.income : semantic.expense,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // El saldo solo no dice de dónde salió el dinero: sin las dos
              // cifras de abajo el usuario no ve si ganó o gastó.
              Text(
                '${CurrencyFormatter.cop.format(income)} de ingresos · '
                '${CurrencyFormatter.cop.format(expense)} de gastos',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
