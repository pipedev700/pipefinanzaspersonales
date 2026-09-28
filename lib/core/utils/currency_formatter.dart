import 'package:intl/intl.dart';

/// D8 — Enum para desacoplar la lógica de negocio de COP.
/// El dominio nunca formatea moneda; solo la capa de presentación.
enum CurrencyCode { cop, usd, mxn }

/// §9 — "25.000" sin decimales; con decimales: "25.000,50".
///
/// La unidad de [format] es la **unidad mínima** de la moneda: para COP es el
/// peso, así que no se divide. Por eso `Movement.amount` es un entero.
///
/// Construir un `NumberFormat` no es gratis, así que se cachea por instancia.
/// Por eso la clase no es `const`: declárala como `final` en el widget.
class CurrencyFormatter {
  CurrencyFormatter(this.code, {this.locale = 'es_CO'});

  /// Instancia compartida para el caso por defecto de la app.
  static final cop = CurrencyFormatter(CurrencyCode.cop);

  final CurrencyCode code;
  final String locale;

  String get symbol => switch (code) {
    CurrencyCode.cop => r'$',
    CurrencyCode.usd => r'$',
    CurrencyCode.mxn => r'$',
  };

  /// §9 — COP se muestra sin decimales; el resto, con dos.
  int get decimalDigits => switch (code) {
    CurrencyCode.cop => 0,
    CurrencyCode.usd || CurrencyCode.mxn => 2,
  };

  late final NumberFormat _pattern = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimalDigits,
  );

  /// Formatea usando el valor absoluto. El signo lo pone quien llama, porque
  /// un saldo negativo y un gasto alto se muestran distinto (§13).
  String format(int amount) => '$symbol${_pattern.format(amount.abs())}';

  /// Con signo explícito: usado por el balance del dashboard.
  String formatSigned(int amount) =>
      amount < 0 ? '-${format(amount)}' : '+${format(amount)}';
}
