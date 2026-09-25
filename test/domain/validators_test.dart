import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/utils/validators.dart';

void main() {
  group('validateAmount', () {
    test('acepta un entero positivo', () {
      expect(validateAmount('25000').isValid, isTrue);
    });

    test('rechaza vacío y nulo', () {
      expect(validateAmount(null).isValid, isFalse);
      expect(validateAmount('').isValid, isFalse);
      expect(validateAmount('   ').isValid, isFalse);
    });

    test('rechaza cero', () {
      expect(validateAmount('0').isValid, isFalse);
    });

    test('rechaza negativos con y sin espacios', () {
      expect(validateAmount('-5').isValid, isFalse);
      expect(validateAmount('-5000').isValid, isFalse);
      expect(validateAmount(' +10').isValid, isFalse);
    });

    test('rechaza decimales con punto o coma', () {
      expect(validateAmount('100.50').isValid, isFalse);
      expect(validateAmount('100,50').isValid, isFalse);
    });

    test('rechaza texto y símbolos', () {
      expect(validateAmount('abc').isValid, isFalse);
      expect(validateAmount(r'$25000').isValid, isFalse);
    });

    test('acepta un monto grande pero dentro del techo', () {
      expect(validateAmount('$maxAmount').isValid, isTrue);
      expect(validateAmount('${maxAmount + 1}').isValid, isFalse);
    });
  });

  group('validateDescription', () {
    test('la descripción es opcional', () {
      expect(validateDescription(null).isValid, isTrue);
      expect(validateDescription('').isValid, isTrue);
    });

    test('acepta hasta 100 caracteres', () {
      expect(validateDescription('a' * maxDescriptionLength).isValid, isTrue);
    });

    test('rechaza más de 100 caracteres', () {
      expect(
        validateDescription('a' * (maxDescriptionLength + 1)).isValid,
        isFalse,
      );
    });
  });

  group('validateDate', () {
    final now = DateTime(2026, 3, 15, 18, 30);

    test('rechaza nula', () {
      expect(validateDate(null, now: now).isValid, isFalse);
    });

    test('acepta hoy ignorando la hora', () {
      expect(validateDate(DateTime(2026, 3, 15, 1), now: now).isValid, isTrue);
    });

    test('acepta el pasado', () {
      expect(validateDate(DateTime(2026, 3, 14), now: now).isValid, isTrue);
      expect(validateDate(DateTime(2025, 1, 1), now: now).isValid, isTrue);
    });

    test('rechaza mañana', () {
      expect(validateDate(DateTime(2026, 3, 16), now: now).isValid, isFalse);
    });
  });

  group('validateMovement', () {
    final now = DateTime(2026, 3, 15);

    test('acepta un movimiento completo válido', () {
      expect(
        validateMovement(
          amount: '25000',
          description: 'Almuerzo',
          date: DateTime(2026, 3, 14),
          categoryId: 1,
          now: now,
        ).isValid,
        isTrue,
      );
    });

    test('devuelve el primer error en el orden de la pantalla', () {
      // Monto inválido + categoría ausente: gana el monto.
      expect(
        validateMovement(
          amount: '0',
          description: '',
          date: DateTime(2026, 3, 14),
          categoryId: null,
          now: now,
        ).error,
        'El monto debe ser mayor a cero',
      );

      // Monto válido, fecha futura, categoría ausente: gana la fecha.
      expect(
        validateMovement(
          amount: '25000',
          description: '',
          date: DateTime(2026, 3, 20),
          categoryId: null,
          now: now,
        ).error,
        'La fecha no puede ser futura',
      );

      // Todo válido salvo la categoría.
      expect(
        validateMovement(
          amount: '25000',
          description: '',
          date: DateTime(2026, 3, 14),
          categoryId: null,
          now: now,
        ).error,
        'Selecciona una categoría',
      );
    });

    test('sin categoría no deja pasar aunque el resto esté bien', () {
      expect(
        validateMovement(
          amount: '1',
          description: 'x',
          date: DateTime(2026, 3, 14),
          categoryId: null,
          now: now,
        ).isValid,
        isFalse,
      );
    });
  });
}
