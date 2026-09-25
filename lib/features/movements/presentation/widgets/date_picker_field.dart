import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';

/// §15 — Fecha por defecto: hoy. `lastDate` impide elegir futuro.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          // `showDatePicker` exige `initialDate` dentro de [first, last].
          initialDate: _clamp(value, today),
          firstDate: DateTime(today.year - 5),
          lastDate: today,
          helpText: 'Selecciona la fecha',
          cancelText: 'Cancelar',
          confirmText: 'Aceptar',
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha',
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          value == null
              ? 'Selecciona una fecha'
              : AppDateUtils.formatShort(value!),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  /// Si el valor cae fuera del rango permitted, se usa hoy. Sin esto, abrir un
  /// movimiento con fecha futura (dato corrupto) lanzaría la aserción de
  /// `showDatePicker`.
  static DateTime _clamp(DateTime? value, DateTime today) {
    if (value == null) return today;
    final normalized = DateTime(value.year, value.month, value.day);
    if (normalized.isAfter(today)) return today;
    if (normalized.isBefore(DateTime(today.year - 5))) return today;
    return normalized;
  }
}
