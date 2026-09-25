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
          // La etiqueta vive en el enum: si mañana se renombra el tipo, el
          // texto del selector cambia con él en vez de quedar desincronizado.
          label: Text(MovementType.expense.label),
          icon: Icon(Icons.trending_down, color: semantic.expense),
        ),
        ButtonSegment(
          value: MovementType.income,
          label: Text(MovementType.income.label),
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
