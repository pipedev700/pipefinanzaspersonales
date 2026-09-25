import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/movement_form_screen.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/date_picker_field.dart';

import '../helpers/fakes.dart';

/// El formulario se abre con `context.pop()`, así que necesita un `GoRouter`
/// real: sin él la pantalla revienta al guardar. Se monta como en producción,
/// con una pantalla de inicio desde la que se navega.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
          // `push` y no `go`: el formulario se cierra con `context.pop()`, y
          // `go` reemplazaría la pila dejando nada a lo que volver.
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  const Text('INICIO'),
                  TextButton(
                    onPressed: () => context.push('/nuevo'),
                    child: const Text('ABRIR_NUEVO'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/editar/42'),
                    child: const Text('ABRIR_EDITAR'),
                  ),
                ],
              ),
            ),
          ),
      GoRoute(path: '/nuevo', builder: (_, _) => const MovementFormScreen()),
      GoRoute(
        path: '/editar/:id',
        builder: (_, state) =>
            MovementFormScreen(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
}

Movement buildExisting({
  int id = 42,
  int amount = 45000,
  MovementType type = MovementType.expense,
  int categoryId = 2,
  String categoryName = 'Transporte',
  DateTime? date,
  String description = 'Pasaje',
}) {
  return Movement(
    id: id,
    amount: amount,
    type: type,
    category: buildCategory(id: categoryId, name: categoryName),
    date: date ?? DateTime(2026, 2, 10),
    description: description,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  late FakeMovementRepository movements;
  late FakeCategoryRepository categories;
  late GoRouter router;

  setUp(() {
    movements = FakeMovementRepository();
    categories = FakeCategoryRepository();
    router = buildRouter();
  });
  tearDown(() async {
    router.dispose();
    await movements.dispose();
    await categories.dispose();
  });

  /// Superficie alta: el formulario es un `ListView` largo y en la ventana
  /// de 800x600 del test los campos inferiores ni siquiera se construyen.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movementRepositoryProvider.overrideWithValue(movements),
          categoryRepositoryProvider.overrideWithValue(categories),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openNew(WidgetTester tester) async {
    await mount(tester);
    await tester.tap(find.text('ABRIR_NUEVO'));
    await tester.pumpAndSettle();
  }

  Future<void> openEdit(WidgetTester tester) async {
    await mount(tester);
    await tester.tap(find.text('ABRIR_EDITAR'));
    await tester.pumpAndSettle();
  }

  /// Escribe el monto y elige la primera categoría visible.
  Future<void> fill(WidgetTester tester, {String amount = '25000'}) async {
    await tester.enterText(find.widgetWithText(TextField, '0'), amount);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
  }

  group('campos y validación', () {
    testWidgets('muestra monto, categoría, fecha y descripción', (tester) async {
      useTallScreen(tester);
      await openNew(tester);

      expect(find.text('Nuevo movimiento'), findsOneWidget);
      expect(find.text('Monto'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Fecha'), findsOneWidget);
      expect(find.text('Descripción (opcional)'), findsOneWidget);
    });

    testWidgets('guardar sin categoría no crea nada y muestra el error', (
      tester,
    ) async {
      useTallScreen(tester);
      await openNew(tester);

      await tester.enterText(find.widgetWithText(TextField, '0'), '25000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(movements.creados, isEmpty);
      expect(find.text('Selecciona una categoría'), findsOneWidget);
    });

    testWidgets('el monto solo admite dígitos', (tester) async {
      useTallScreen(tester);
      await openNew(tester);

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, '0'),
      );
      expect(field.inputFormatters, hasLength(2));
      expect(field.keyboardType, TextInputType.number);

      // `-`, `$` y la coma quedan fuera: `digitsOnly` los descarta.
      await tester.enterText(find.widgetWithText(TextField, '0'), r'-$5,50');
      await tester.pumpAndSettle();
      expect(find.text('550'), findsOneWidget);
    });

    testWidgets('guarda y vuelve a la pantalla anterior con SnackBar', (
      tester,
    ) async {
      useTallScreen(tester);
      await openNew(tester);
      await fill(tester);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(movements.creados, hasLength(1));
      expect(movements.creados.single.amount, 25000);
      expect(movements.creados.single.categoryId, 1);
      // Volvió al inicio y lo confirmó.
      expect(find.text('INICIO'), findsOneWidget);
      expect(find.text('Movimiento registrado'), findsOneWidget);
    });

    testWidgets('un movimiento nuevo aparece sin reiniciar la app', (
      tester,
    ) async {
      useTallScreen(tester);
      await openNew(tester);
      await fill(tester, amount: '999');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // El repositorio se actualizó en vivo: el stream emitió la lista nueva.
      expect(movements.total, 1);
      expect(movements.list.single.amount, 999);
    });
  });

  group('tipo de movimiento', () {
    testWidgets('alterna entre Gasto e Ingreso', (tester) async {
      useTallScreen(tester);
      await openNew(tester);

      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();

      // El grid pasa a las categorías de ingreso.
      expect(find.text('Salario'), findsOneWidget);
      expect(find.text('Comida'), findsNothing);
    });

    testWidgets('cambiar de tipo limpia la categoría seleccionada', (
      tester,
    ) async {
      useTallScreen(tester);
      await openNew(tester);

      await tester.enterText(find.widgetWithText(TextField, '0'), '25000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Si `setType` no limpiara la categoría, el borrador llevaría el id de
      // una categoría de gasto junto a un tipo de ingreso: la base lo
      // aceptaría y el desglose del dashboard lo mostraría mal.
      expect(movements.creados.single.type, MovementType.income);
      expect(movements.creados.single.categoryId, 3);
    });
  });

  group('edición', () {
    testWidgets('precarga monto, tipo, categoría, fecha y descripción', (
      tester,
    ) async {
      useTallScreen(tester);
      movements.emit([buildExisting()]);
      await openEdit(tester);

      expect(find.text('Editar movimiento'), findsOneWidget);
      expect(find.text('45000'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('10 feb 2026'), findsOneWidget);
      expect(find.text('Pasaje'), findsOneWidget);
    });

    testWidgets('actualiza en vez de crear', (tester) async {
      useTallScreen(tester);
      movements.emit([buildExisting()]);
      await openEdit(tester);

      await tester.enterText(find.widgetWithText(TextField, '45000'), '50000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(movements.creados, isEmpty);
      expect(movements.total, 1);
      expect(movements.list.single.amount, 50000);
      expect(find.text('Movimiento actualizado'), findsOneWidget);
    });
  });

  group('eliminar', () {
    testWidgets('pide confirmación y cancelar no borra', (tester) async {
      useTallScreen(tester);
      movements.emit([buildExisting()]);
      await openEdit(tester);

      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar movimiento'), findsOneWidget);
      expect(movements.total, 1);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(movements.total, 1);
    });

    testWidgets('confirmar borra el movimiento', (tester) async {
      useTallScreen(tester);
      movements.emit([buildExisting()]);
      await openEdit(tester);

      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(movements.total, 0);
      expect(find.text('Movimiento eliminado'), findsOneWidget);
    });
  });

  group('límites', () {
    testWidgets('la descripción se limita a 100 caracteres', (tester) async {
      useTallScreen(tester);
      await openNew(tester);

      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.maxLength, 100);
    });

    testWidgets('el date picker no ofrece fechas futuras', (tester) async {
      useTallScreen(tester);
      await openNew(tester);

      // Se apunta al `InkWell` del campo, no al texto de la etiqueta: la
      // etiqueta vive dentro del `InputDecorator` y no es hit-testable.
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerField),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      final now = DateTime.now();
      expect(
        dialog.lastDate,
        DateTime(now.year, now.month, now.day),
      );
    });
  });
}
