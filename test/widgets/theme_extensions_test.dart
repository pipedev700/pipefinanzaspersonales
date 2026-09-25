import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/theme/theme_extensions.dart';

/// S08 — `copyWith` y `lerp` de [SemanticColors].
///
/// Ninguna de las dos se llama desde el código de la app: las invoca el
/// framework (`ThemeData.copyWith` y la animación de temas). Están ahí por
/// contrato de `ThemeExtension`, así que no se pueden borrar, pero sí
/// verificar: un `lerp` mal escrito se manifiesta como un color que salta
/// durante la transición de tema, que es difícil de atribuir a su causa.
void main() {
  const a = SemanticColors(
    income: Color(0xFF000000),
    expense: Color(0xFF000000),
    warning: Color(0xFF000000),
    surfaceVariant: Color(0xFF000000),
  );
  const b = SemanticColors(
    income: Color(0xFFFFFFFF),
    expense: Color(0xFFFFFFFF),
    warning: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFFFFFFF),
  );

  group('copyWith', () {
    test('sin argumentos devuelve colores equivalentes', () {
      final copy = a.copyWith();

      expect(copy.income, a.income);
      expect(copy.expense, a.expense);
      expect(copy.warning, a.warning);
      expect(copy.surfaceVariant, a.surfaceVariant);
    });

    test('cambia solo el campo indicado', () {
      final copy = a.copyWith(expense: const Color(0xFFFF0000));

      expect(copy.expense, const Color(0xFFFF0000));
      expect(copy.income, a.income);
      expect(copy.warning, a.warning);
      expect(copy.surfaceVariant, a.surfaceVariant);
    });

    test('no muta el original', () {
      a.copyWith(income: const Color(0xFF00FF00));
      expect(a.income, const Color(0xFF000000));
    });
  });

  group('lerp', () {
    test('con t = 0 devuelve el propio', () {
      final mid = a.lerp(b, 0);
      expect(mid.income, a.income);
      expect(mid.surfaceVariant, a.surfaceVariant);
    });

    test('con t = 1 devuelve el otro', () {
      final mid = a.lerp(b, 1);
      expect(mid.income, b.income);
      expect(mid.surfaceVariant, b.surfaceVariant);
    });

    test('con t = 0.5 interpola los cuatro canales', () {
      final mid = a.lerp(b, 0.5);
      for (final color in [
        mid.income,
        mid.expense,
        mid.warning,
        mid.surfaceVariant,
      ]) {
        expect(color.r, closeTo(0.5, 0.01), reason: 'rojo');
        expect(color.g, closeTo(0.5, 0.01), reason: 'verde');
        expect(color.b, closeTo(0.5, 0.01), reason: 'azul');
      }
    });

    test('con una extensión de otro tipo devuelve el propio sin fallar', () {
      // `ThemeExtension.lerp` puede recibir `null` durante la primera
      // interpolación del tema: devolver `this` es lo que evita el crash.
      expect(a.lerp(null, 0.5).income, a.income);
    });
  });
}
