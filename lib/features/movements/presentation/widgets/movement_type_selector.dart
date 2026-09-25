import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/movement_type.dart';

/// §12 — Selector de dos opciones: Gasto o Ingreso.
class MovementTypeSelector extends StatelessWidget {
  const MovementTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MovementType value;
  final ValueChanged<MovementType> onChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return SegmentedButton<MovementType>(
      segments: [
        ButtonSegment(
          value: MovementType.expense,
          label: const Text('Gasto'),
          icon: Icon(Icons.trending_down, color: semantic.expense),
        ),
        ButtonSegment(
          value: MovementType.income,
          label: const Text('Ingreso'),
          icon: Icon(Icons.trending_up, color: semantic.income),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        onChanged(selection.first);
      },
      showSelectedIcon: false,
    );
  }
}
