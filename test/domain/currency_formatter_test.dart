import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/utils/currency_formatter.dart';

void main() {
  group('COP', () {
    final cop = CurrencyFormatter(CurrencyCode.cop);

    test('sin decimales y con separador de miles', () {
      expect(cop.format(0), r'$0');
      expect(cop.format(25), r'$25');
      expect(cop.format(25000), r'$25.000');
      expect(cop.format(1500000), r'$1.500.000');
    });

    test('el valor absoluto ignora el signo', () {
      expect(cop.format(-25000), r'$25.000');
    });

    test('formatSigned pone el signo explícito', () {
      expect(cop.formatSigned(25000), r'+$25.000');
      expect(cop.formatSigned(-25000), r'-$25.000');
      expect(cop.formatSigned(0), r'+$0');
    });
  });

  group('monedas con decimales', () {
    test('USD con dos decimales', () {
      final usd = CurrencyFormatter(CurrencyCode.usd, locale: 'en_US');
      expect(usd.format(25), r'$25.00');
      expect(usd.format(1234), r'$1,234.00');
    });

    test('MXN con dos decimales', () {
      final mxn = CurrencyFormatter(CurrencyCode.mxn);
      expect(mxn.format(25000), r'$25.000,00');
    });
  });

  test('la instancia compartida es COP', () {
    expect(CurrencyFormatter.cop.code, CurrencyCode.cop);
    expect(CurrencyFormatter.cop.format(25000), r'$25.000');
  });
}
