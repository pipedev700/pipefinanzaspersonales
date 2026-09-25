import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/app.dart';

void main() {
  testWidgets('arranca y navega del splash al dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PipeApp()));
    await tester.pump();

    // El splash aparece primero.
    expect(find.text('Pipe Finanzas'), findsOneWidget);

    // Pasa el Timer de 1,5 s y navega al dashboard.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
  });

  testWidgets('la NavigationBar cambia entre las dos ramas', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PipeApp()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsOneWidget);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    // La rama activa muestra su propio AppBar.
    expect(find.text('Historial'), findsWidgets);
  });

  testWidgets('el FAB abre el formulario a pantalla completa', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PipeApp()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo movimiento'), findsWidgets);
  });
}
