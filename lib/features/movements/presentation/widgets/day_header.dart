import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/financial_values.dart';

/// Encabezado de un grupo de movimientos: la fecha a la izquierda y **cuánto
/// sumó el día** a la derecha.
///
/// Se pinta el [DailyGroup.net] (ingresos − gastos) y no solo el gasto: un día
/// con $3.000.000 de ingresos y $100.000 de gastos cierra en +$2.900.000, y
/// mostrar "-$100.000" en rojo comunicaba un déficit que no ocurrió. Cuando el
/// día tiene los dos tipos, el desglose va en el `tooltip` del número para que
/// la fila siga entrando en 360 px sin cutting nada.
///
/// Vive en su propio archivo porque lo usan el historial y el histórico: la
/// versión anterior estaba dentro de `history_screen.dart` como clase privada.
class DayHeader extends StatelessWidget {
  const DayHeader({required this.group, super.key});

  final DailyGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    // Sin color el encabezado queda con `color: null` y lo resuelve el
    // ambiente: salía blanco sobre `surface`, igual que le pasaba al monto y
    // al nombre de las categorías.
    final titleStyle = AppTypography.label.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // `format` saca el valor absoluto, así que el signo se pone a mano:
          // interpolar `net` directamente llevaría dos.
          Tooltip(
            message: _breakdown,
            child: Text(
              '${group.isPositive ? '+' : '-'}${CurrencyFormatter.cop.format(group.net)}',
              style: titleStyle.copyWith(
                color: group.isPositive ? semantic.income : semantic.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `+` y `−` de cada lado del día. Con un solo tipo el mensaje repite el
  /// número que ya está a la vista, pero en texto largo el `Tooltip` también
  /// sirve de etiqueta para el lector de pantalla.
  String get _breakdown {
    if (group.totalIncome == 0) {
      return 'Solo gastos: ${CurrencyFormatter.cop.format(group.totalExpense)}';
    }
    if (group.totalExpense == 0) {
      return 'Solo ingresos: ${CurrencyFormatter.cop.format(group.totalIncome)}';
    }
    return 'Ingresos ${CurrencyFormatter.cop.format(group.totalIncome)} · '
        'Gastos ${CurrencyFormatter.cop.format(group.totalExpense)}';
  }
}
