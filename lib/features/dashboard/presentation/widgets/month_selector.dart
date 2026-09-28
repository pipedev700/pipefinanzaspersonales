import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';

/// §13 — Selector ‹ mes ›. `onNext` nulo deshabilita el botón.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
        ),
        Expanded(
          child: Center(
            child: Text(
              AppDateUtils.formatMonth(month),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
        ),
      ],
    );
  }
}
