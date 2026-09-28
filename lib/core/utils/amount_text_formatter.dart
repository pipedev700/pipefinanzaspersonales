import 'package:flutter/services.dart';

/// Separador de miles para el campo de monto.
///
/// El monto se guarda como entero, pero se **escribe** con puntos de miles:
/// `25000` se ve `25.000`. En `es_CO` el punto es el separador de miles y la
/// coma el decimal, así que se agrupa con punto y se sigue rechazando la coma
/// como decimal (§15).
///
/// El agrupado vive en una función pura, [groupThousands], y el `formatter` es
/// una capa fina sobre ella: así se puede testear el agrupado sin widget y el
/// `TextField` no tiene que saber de números.
const thousandsSeparator = '.';

/// Agrupa [digits] con puntos cada tres cifras desde la derecha.
///
/// Quita cualquier separador que ya venga: la función es idempotente y sirve
/// tanto para el texto que llega del teclado como para el que ya tenía el
/// campo. `''` y valores no numéricos se devuelven tal cual, para que el
/// `formatter` pueda confiar en que nunca lanza.
///
/// El separador va **detrás** de la cifra cuando las que quedan a su izquierda
/// son un múltiplo de tres y hay alguna: `45000` → `45.000`, `1000` → `1.000`
/// y `999` se queda como está.
String groupThousands(String digits) {
  final clean = digits.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.isEmpty) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < clean.length; i++) {
    buffer.write(clean[i]);
    final pending = clean.length - i - 1;
    if (pending > 0 && pending % 3 == 0) buffer.write(thousandsSeparator);
  }
  return buffer.toString();
}

/// Quita los separadores y devuelve el entero, o `null` si no hay dígitos.
///
/// Es la inversa de [groupThousands] y el único punto donde el texto del campo
/// se convierte en número: el controlador y el validador pasan por aquí, de
/// modo que un `25.000` en pantalla y un `25000` en la base nunca se
/// contradicen.
int? parseAmountText(String? text) {
  final clean = (text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  return clean.isEmpty ? null : int.tryParse(clean);
}

/// `formatter` que reagrupa el campo entero en cada pulsación.
///
/// Va **al revés** que un `digitsOnly`: primero se limpian los separadores
/// (para que borrar un punto no rompa el número) y luego se vuelve a agrupar
/// el texto completo, no solo los caracteres nuevos. Si solo se agrupara lo
/// tecleado, al llegar al cuarto dígito aparecerían `2.5.000` y al borrar un
/// carácter los puntos quedarían colgando.
///
/// El cursor se conserva contando **dígitos** por delante de él: con el texto
/// reagrupado, el offset crudo apuntaría a otro sitio tras cada punto nuevo.
class ThousandsSeparatorTextInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorTextInputFormatter({this.maxDigits = 12});

  /// `maxAmount` son 12 dígitos. El límite va en dígitos y no en caracteres
  /// porque el texto con puntos es más largo: 12 dígitos ocupan 15
  /// caracteres.
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;

    // Cuántos dígitos había antes del cursor, para devolverlo a la misma
    // cifra y no al mismo índice de carácter.
    final digitsBeforeCursor = newValue.text
        .substring(
          0,
          newValue.selection.baseOffset.clamp(0, newValue.text.length),
        )
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    final text = groupThousands(capped);
    final cursor = _offsetAfterDigits(text, digitsBeforeCursor);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  /// Índice del carácter que sigue a los primeros [digits] dígitos de [text].
  static int _offsetAfterDigits(String text, int digits) {
    if (digits <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] != thousandsSeparator) seen++;
      if (seen == digits) return i + 1;
    }
    return text.length;
  }
}
