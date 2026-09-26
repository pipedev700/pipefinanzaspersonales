import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/shared/widgets/empty_state.dart';

/// `EmptyState` se pinta dentro de cajas de altura fija en el dashboard, el
/// historial y el histórico. Con una `Column` pelada, el texto se salía y
/// Flutter pintaba la franja de "BOTTOM OVERFLOWED BY 74 PIXELS" — el aviso
/// que veía el usuario. Estos tests fijan que el contenido se ve entero
/// siempre: centrado si cabe, con scroll si no cabe.
void main() {
  /// Monta el estado vacío dentro de una caja de [height], que es como lo
  /// usan las pantallas.
  Future<void> pumpInBox(
    WidgetTester tester, {
    required double height,
    double scale = 1.0,
    String message =
        'Aún no tienes movimientos. Registra tu primer ingreso '
        'o gasto para ver tu resumen.',
    String? actionLabel,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: height,
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Sin movimientos',
              message: message,
              actionLabel: actionLabel,
              onAction: actionLabel == null ? null : () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('centra el contenido cuando cabe', (tester) async {
    await pumpInBox(tester, height: 600);

    expect(find.text('Sin movimientos'), findsOneWidget);
    final box = tester.getRect(find.byType(EmptyState));
    final text = tester.getRect(find.text('Sin movimientos'));
    // Con la caja de 600 el texto queda hacia el centro, no pegado arriba.
    expect(text.top, greaterThan(box.top + 100));
  });

  testWidgets('no desborda con la fuente del sistema grande', (tester) async {
    for (final scale in const [1.0, 1.15, 1.3, 1.5, 2.0]) {
      await pumpInBox(tester, height: 240, scale: scale);
      expect(
        tester.takeException(),
        isNull,
        reason: 'desbordó con la fuente al $scale en una caja de 240',
      );
      expect(find.text('Sin movimientos'), findsOneWidget);
    }
  });

  testWidgets('el texto largo se hace scroll, no se corta', (tester) async {
    await pumpInBox(
      tester,
      height: 180,
      scale: 1.5,
      message:
          'Este mensaje es mucho más largo de lo que cabe en una caja '
          'de 180 píxeles con la fuente grande del sistema, y aun así el '
          'usuario tiene que poder leerlo entero.',
    );

    expect(tester.takeException(), isNull);

    final scrollable = find.byType(SingleChildScrollView);
    expect(scrollable, findsOneWidget);
    // Y se puede desplazar hasta el final.
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('con botón de acción tampoco desborda', (tester) async {
    await pumpInBox(
      tester,
      height: 150,
      scale: 1.3,
      actionLabel: 'Registrar movimiento',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Registrar movimiento'), findsOneWidget);
  });
}
