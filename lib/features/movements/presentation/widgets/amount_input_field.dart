import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/amount_text_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';

/// §9 y §15 — Campo numérico con prefijo de moneda y separador de miles.
///
/// El usuario escribe `25.000` y no `25000`: el separador lo pone
/// [ThousandsSeparatorTextInputFormatter] al vuelo y
/// [parseAmountText] lo quita al guardar, así que el estado sigue siendo una
/// cadena de dígitos y el dominio sigue recibiendo un entero. El estado
/// intermedio con puntos es solo de presentación.
class AmountInputField extends StatelessWidget {
  const AmountInputField({
    required this.controller,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: const [
        // Cubre `digitsOnly`, el reagrupado y el tope de 12 dígitos. No se
        // encadenan `digitsOnly` ni `LengthLimitingTextInputFormatter`: cuentan
        // caracteres, y aquí los separadores forman parte del texto.
        ThousandsSeparatorTextInputFormatter(),
      ],
      // Se usa `AppTypography.display` directamente y no el slot
      // `headlineMedium` del tema, para que el campo no cambie de aspecto si
      // alguien reasigna ese slot. El color va explícito porque
      // `AppTypography` son constantes sin color: sin esto el monto quedaba
      // con `color: null`, lo resolvía el ambiente y salía blanco.
      style: AppTypography.display.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: 'Monto',
        hintText: '0',
        prefixText: '${CurrencyFormatter.cop.symbol} ',
        prefixStyle: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        errorText: errorText,
        errorMaxLines: 2,
      ),
    );
  }
}
