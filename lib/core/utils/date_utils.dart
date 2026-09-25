import 'package:flutter/material.dart';

const _kMonthNames = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const _kShortMonths = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// D10 — Los nombres de mes salen de listas constantes: no se usa `DateFormat`
/// porque `intl` exige `initializeDateFormatting` para fechas no-sistema,
/// que es un fallo de runtime fácil de no detectar. La app es solo en español.
abstract final class AppDateUtils {
  static String monthName(int month) => _kMonthNames[month - 1];

  /// Abrviatura de 3 letras para el eje del gráfico: "ene", "feb"…
  ///
  /// Vive aquí y no como `monthName(m).substring(0, 3)` en el widget: las
  /// abreviaturas en español no siempre son las tres primeras letras del
  /// nombre ("Septiembre" → "Sep"), y duplicar el criterio en dos sitios es
  /// la forma corta de que se desincronicen.
  static String shortMonthName(int month) => _kShortMonths[month - 1];

  /// §12 — "13 ene 2026"
  static String formatShort(DateTime date) =>
      '${date.day} ${_kShortMonths[date.month - 1]} ${date.year}';

  /// §12 — "13 ene 2026, 14:30"
  static String formatShortWithTime(DateTime date) =>
      '${formatShort(date)}, ${_two(date.hour)}:${_two(date.minute)}';

  /// Etiqueta de mes para el selector: "Enero 2026"
  static String formatMonth(DateTime date) =>
      '${monthName(date.month)} ${date.year}';

  /// Etiqueta de mes relativo cuando aplica.
  static String formatMonthRelative(DateTime date, DateTime now) {
    if (date.year == now.year && date.month == now.month) return 'Este mes';
    final prev = DateTime(now.year, now.month - 1);
    if (date.year == prev.year && date.month == prev.month) {
      return 'Mes anterior';
    }
    return formatMonth(date);
  }

  /// Rango [start, end) del mes: el último día a medianoche del mes
  /// siguiente. Comparable, seguro para índices y para filtrar en SQL.
  static DateTimeRange monthRange(DateTime date) => DateTimeRange(
    start: DateTime(date.year, date.month),
    end: DateTime(date.year, date.month + 1),
  );

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _two(int value) => value.toString().padLeft(2, '0');
}
