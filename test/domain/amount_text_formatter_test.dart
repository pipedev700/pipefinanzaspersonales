import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/utils/amount_text_formatter.dart';

/// El agrupado es una función pura a propósito: se testea sin widget, que es
/// más rápido y más preciso que teclear en el `TextField` para cada caso.
void main() {
  group('groupThousands', () {
    test('agrupa desde la derecha cada tres cifras', () {
      expect(groupThousands('1'), '1');
      expect(groupThousands('999'), '999');
      expect(groupThousands('1000'), '1.000');
      expect(groupThousands('45000'), '45.000');
      expect(groupThousands('250000'), '250.000');
      expect(groupThousands('1234567'), '1.234.567');
      expect(groupThousands('999999999999'), '999.999.999.999');
    });

    test('es idempotente: agrupar lo ya agrupado no cambia nada', () {
      expect(groupThousands('45.000'), '45.000');
      expect(groupThousands('1.234.567'), '1.234.567');
    });

    test('descarta todo lo que no es dígito', () {
      expect(groupThousands(r'-$5,50'), '550');
      expect(groupThousands('  25 000 '), '25.000');
      expect(groupThousands('abc'), '');
      expect(groupThousands(''), '');
    });
  });

  group('parseAmountText', () {
    test('quita los separadores y devuelve el entero', () {
      expect(parseAmountText('45.000'), 45000);
      expect(parseAmountText('999.999.999.999'), 999999999999);
      expect(parseAmountText('550'), 550);
    });

    test('devuelve null si no hay dígitos', () {
      expect(parseAmountText(null), isNull);
      expect(parseAmountText(''), isNull);
      expect(parseAmountText('.'), isNull);
    });
  });

  group('ThousandsSeparatorTextInputFormatter', () {
    const formatter = ThousandsSeparatorTextInputFormatter();

    /// Aplica el `formatter` como lo haría el `TextField`: el valor nuevo
    /// llega con el texto ya escrito y el cursor donde el dedo lo dejó.
    TextEditingValue apply(String text, {int cursor = -1}) {
      final at = cursor < 0 ? text.length : cursor;
      return formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: at),
        ),
      );
    }

    test('reagrupa el texto completo, no solo lo tecleado', () {
      // '2.5.000' sería el resultado de agrupar por trozos: agrupar entero.
      expect(apply('25').text, '25');
      expect(apply('250').text, '250');
      expect(apply('2500').text, '2.500');
      expect(apply('25000').text, '25.000');
      expect(apply('2500000').text, '2.500.000');
    });

    test('borrar un separador no rompe el número', () {
      // El usuario borra el punto: el texto vuelve a ser dígitos y se
      // reagrupa, no queda '2.5000' colgando.
      expect(apply('2.500').text, '2.500');
      expect(apply('2500').text, '2.500');
    });

    test('borrar la última cifra reagrupa el resto', () {
      // El campo entrega el texto ya editado: se borró el último '0'.
      final result = apply('2.50', cursor: 4);
      expect(result.text, '250');
      expect(result.selection.baseOffset, 3);
    });

    test('mantiene el cursor en la misma cifra al escribir en medio', () {
      // El campo tiene '25.000' y el usuario escribe un '3' detrás del '5'.
      // El texto crudo llega como '253.000' y el cursor en la posición 4.
      final result = apply('253.000', cursor: 4);
      expect(result.text, '253.000');
      expect(
        result.selection.baseOffset,
        3,
        reason: 'el cursor va detrás del 3 tecleado, no del punto ni al final',
      );
    });

    test('el cursor no se sale del texto', () {
      final result = apply('25.000', cursor: 99);
      expect(result.selection.baseOffset, result.text.length);
    });

    test('topa en 12 dígitos, no en 12 caracteres', () {
      const conTecho = ThousandsSeparatorTextInputFormatter();
      final result = conTecho.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1234567890123456',
          selection: TextSelection.collapsed(offset: 16),
        ),
      );
      expect(result.text, '123.456.789.012');
    });
  });
}
