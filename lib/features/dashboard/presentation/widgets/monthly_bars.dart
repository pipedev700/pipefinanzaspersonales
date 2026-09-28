import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../movements/domain/financial_values.dart';

/// §13 — Barras comparativas de ingresos vs gastos de los últimos 6 meses.

/// Altura total del área del gráfico, y la parte que se reparte entre las
/// barras. La diferencia es el hueco del rótulo del mes y del `padding`.
const double kChartHeight = 140;
const double kBarAreaHeight = 112;

class MonthlyBars extends StatelessWidget {
  const MonthlyBars({required this.bars, super.key});

  final List<MonthlyBar> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final semantic = context.semantic;

    // Una única escala para los dos colores: si cada barra midiera contra su
    // propio valor, un gasto pequeño junto a un ingreso grande parecería
    // igual de importante.
    final maxValue = bars.fold<int>(0, (acc, b) => b.max > acc ? b.max : acc);

    // Todo cero: pintar un eje de barras de altura cero solo confunde.
    if (maxValue == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Últimos 6 meses', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: kChartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in bars)
                    Expanded(
                      child: _BarGroup(
                        bar: b,
                        maxValue: maxValue,
                        incomeColor: semantic.income,
                        expenseColor: semantic.expense,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: semantic.income, label: 'Ingresos'),
                const SizedBox(width: AppSpacing.md),
                _Legend(color: semantic.expense, label: 'Gastos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarGroup extends StatelessWidget {
  const _BarGroup({
    required this.bar,
    required this.maxValue,
    required this.incomeColor,
    required this.expenseColor,
  });

  final MonthlyBar bar;
  final int maxValue;
  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(value: bar.income, max: maxValue, color: incomeColor),
            const SizedBox(width: 3),
            _Bar(value: bar.expense, max: maxValue, color: expenseColor),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppDateUtils.shortMonthName(bar.month.month),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.max, required this.color});

  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Sin barra para el cero, en vez de un mínimo visible: un ingreso de $0
    // no es "un ingreso muy pequeño", es que no hubo ingresos ese mes.
    if (value == 0) return const SizedBox(width: 10);

    final ratio = value / max;
    return Tooltip(
      message: CurrencyFormatter.cop.format(value),
      child: Container(
        width: 10,
        // El mínimo de 2 px evita que una barra muy chica desaparezca y dé la
        // impresión de que el mes no tuvo movimientos.
        height: (kBarAreaHeight * ratio).clamp(2.0, kBarAreaHeight),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
