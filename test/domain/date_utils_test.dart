import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/utils/date_utils.dart';

/// S08 — `date_utils.dart` lo usan el selector de mes, el historial, el
/// gráfico y las cabeceras de día, y hasta S07 no tenía **ningún** test
/// propio: su única cobertura era indirecta, a través de widgets que
/// comprobarían el texto completo.
void main() {
  group('nombres de mes', () {
    test('los 12 meses tienen nombre y abreviatura', () {
      for (var m = 1; m <= 12; m++) {
        expect(AppDateUtils.monthName(m), isNotEmpty, reason: 'mes $m');
        expect(AppDateUtils.shortMonthName(m), hasLength(3), reason: 'mes $m');
      }
    });

    test('la abreviatura de septiembre no son las 3 primeras letras', () {
      // El motivo de existir de `shortMonthName`: "Septiembre".substring(0, 3)
      // da "Sep" con mayúscula y "Agosto" da "Ago" en vez de "ago".
      expect(AppDateUtils.monthName(9), 'Septiembre');
      expect(AppDateUtils.shortMonthName(9), 'sep');
      expect(AppDateUtils.shortMonthName(8), 'ago');
    });

    test('la abreviatura es el prefijo del nombre en minúsculas', () {
      // Invariante entre las dos listas escritas a mano: si alguien añade o
      // renombra un mes en una y no en la otra, el gráfico rotularía el mes
      // equivocado sin fallar. Hoy se cumple en los 12.
      for (var m = 1; m <= 12; m++) {
        final name = AppDateUtils.monthName(m);
        expect(
          AppDateUtils.shortMonthName(m),
          name.toLowerCase().substring(0, 3),
          reason: 'mes $m ($name)',
        );
      }
    });

    test('un mes fuera de rango lanza RangeError, no devuelve null', () {
      expect(() => AppDateUtils.monthName(0), throwsRangeError);
      expect(() => AppDateUtils.monthName(13), throwsRangeError);
      expect(() => AppDateUtils.shortMonthName(0), throwsRangeError);
    });
  });

  group('formatShort', () {
    test('§12 — "13 ene 2026"', () {
      expect(AppDateUtils.formatShort(DateTime(2026, 1, 13)), '13 ene 2026');
    });

    test('no rellena con ceros el día', () {
      expect(AppDateUtils.formatShort(DateTime(2026, 12, 5)), '5 dic 2026');
    });
  });

  group('formatShortWithTime', () {
    test('§12 — añade la hora con dos dígitos', () {
      expect(
        AppDateUtils.formatShortWithTime(DateTime(2026, 3, 9, 7, 5)),
        '9 mar 2026, 07:05',
      );
    });

    test('medianoche sale 00:00', () {
      expect(
        AppDateUtils.formatShortWithTime(DateTime(2026, 3, 9)),
        '9 mar 2026, 00:00',
      );
    });
  });

  group('formatMonth', () {
    test('"Enero 2026"', () {
      expect(AppDateUtils.formatMonth(DateTime(2026, 1, 15)), 'Enero 2026');
    });
  });

  group('formatMonthRelative', () {
    final now = DateTime(2026, 3, 15, 10);

    test('el mes actual se rotula "Este mes"', () {
      expect(
        AppDateUtils.formatMonthRelative(DateTime(2026, 3, 1), now),
        'Este mes',
      );
    });

    test('el mes previo se rotula "Mes anterior"', () {
      expect(
        AppDateUtils.formatMonthRelative(DateTime(2026, 2, 28), now),
        'Mes anterior',
      );
    });

    test('en enero, el mes anterior es diciembre del año previo', () {
      // `DateTime(2026, 0)` normaliza a diciembre de 2025: el borde que
      // se rompe sin normalizar es justo este.
      final enero = DateTime(2026, 1, 10);
      expect(
        AppDateUtils.formatMonthRelative(DateTime(2025, 12, 31), enero),
        'Mes anterior',
      );
    });

    test('cualquier otro mes cae en el nombre absoluto', () {
      expect(
        AppDateUtils.formatMonthRelative(DateTime(2025, 11, 30), now),
        'Noviembre 2025',
      );
      // Del año siguiente todavía no: "Este mes" es solo el mismo mes.
      expect(
        AppDateUtils.formatMonthRelative(DateTime(2026, 4, 1), now),
        'Abril 2026',
      );
    });

    test('el día del mes no influye en la etiqueta', () {
      expect(
        AppDateUtils.formatMonthRelative(DateTime(2026, 3, 31), now),
        'Este mes',
      );
      expect(
        AppDateUtils.formatMonthRelative(DateTime(2026, 3, 1), now),
        'Este mes',
      );
    });
  });
}
