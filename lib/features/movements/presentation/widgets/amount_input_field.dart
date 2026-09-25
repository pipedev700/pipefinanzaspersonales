import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency_formatter.dart';

/// §9 y §15 — Campo numérico con prefijo de moneda.
///
/// `digitsOnly` es la primera barrera: impide escribir letras, el símbolo `$`,
/// el signo `-` y los decimales. `validateAmount` es la segunda, para lo que
/// llegue pegado o por otra vía.
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
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        // `maxAmount` son 12 dígitos: suficiente para el techo de los
        // validadores.
        LengthLimitingTextInputFormatter(12),
      ],
      style: theme.textTheme.headlineMedium?.copyWith(
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
