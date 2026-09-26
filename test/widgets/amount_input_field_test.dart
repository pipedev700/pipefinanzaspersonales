import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/theme/app_colors.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/core/utils/currency_formatter.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/amount_input_field.dart';

/// Regresión del bug: el texto del monto salía blanco.
///
/// La causa era que el campo tomaba su estilo del slot `headlineMedium` del
/// tema, que está reapuntado a `AppTypography.display`, y ese estilo no
/// declara color. El monto quedaba entonces con `color: null`, que el
/// ambiente resolvía a blanco en Android: cifra invisible sobre `surface`
/// blanco. Estos tests fijan el color para que no vuelva a depender del
/// ambiente.
void main() {
  Future<void> pumpField(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AmountInputField(
            controller: TextEditingController(),
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }

  /// Razón de contraste WCAG 2.1 para dos colores opacos.
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final light = la > lb ? la : lb;
    final dark = la > lb ? lb : la;
    return (light + 0.05) / (dark + 0.05);
  }

  testWidgets('el monto usa el color de texto, no queda en null', (
    tester,
  ) async {
    await pumpField(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    final theme = Theme.of(tester.element(find.byType(TextField)));

    expect(
      field.style?.color,
      isNotNull,
      reason:
          'sin color explícito lo resuelve el ambiente y puede salir '
          'ilegible sobre surface',
    );
    expect(field.style?.color, theme.colorScheme.onSurface);
    expect(field.style?.color, AppColors.textPrimary);
  });

  testWidgets('el monto se lee sobre el fondo real del campo', (tester) async {
    await pumpField(tester);
    await tester.enterText(find.byType(AmountInputField), '125000');
    await tester.pump();

    final theme = Theme.of(tester.element(find.byType(TextField)));
    final fill =
        theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;
    final amount = tester
        .widget<TextField>(find.byType(TextField))
        .style!
        .color!;

    // AA para texto normal pide 4.5:1. El monto es a 32px, que califica
    // como texto grande (3:1), pero se comprueba el umbral exigente.
    expect(
      contrast(amount, fill),
      greaterThanOrEqualTo(4.5),
      reason:
          'contraste insuficiente entre la cifra del monto y el fondo '
          'del campo',
    );
  });

  testWidgets('el prefijo de moneda se mantiene en secondary', (tester) async {
    await pumpField(tester);
    final theme = Theme.of(tester.element(find.byType(TextField)));
    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;

    expect(decoration.prefixText, contains(CurrencyFormatter.cop.symbol));
    expect(decoration.prefixStyle?.color, theme.colorScheme.onSurfaceVariant);
  });
}
