import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/category.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/movement_form_screen.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/amount_input_field.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/category_picker.dart';
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

  /// Pantalla de móvil real, no una ventana alta: el formulario cabe entero
  /// en 360x800 con las 10 categorías de gasto, y usar una superficie
  /// holgada escondería justo lo que se quiere comprobar (que no haya
  /// scroll). El test de "sin scroll" de abajo ata este tamaño.
  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
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
    testWidgets('muestra monto, categoría, fecha y descripción', (
      tester,
    ) async {
      usePhoneScreen(tester);
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
      usePhoneScreen(tester);
      await openNew(tester);

      await tester.enterText(find.widgetWithText(TextField, '0'), '25000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(movements.creados, isEmpty);
      expect(find.text('Selecciona una categoría'), findsOneWidget);
    });

    testWidgets('el monto agrupa miles y descarta lo que no es cifra', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await openNew(tester);

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, '0'),
      );
      expect(field.inputFormatters, hasLength(1));
      expect(field.keyboardType, TextInputType.number);

      // `-`, `$` y la coma quedan fuera: el `formatter` se queda solo con los
      // dígitos y los vuelve a agrupar.
      await tester.enterText(find.widgetWithText(TextField, '0'), r'-$5,50');
      await tester.pumpAndSettle();
      expect(find.text('550'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '0'), '25000');
      await tester.pumpAndSettle();
      expect(find.text('25.000'), findsOneWidget);
    });

    testWidgets('el monto con puntos se guarda como entero', (tester) async {
      usePhoneScreen(tester);
      await openNew(tester);

      await tester.enterText(find.widgetWithText(TextField, '0'), '1250000');
      await tester.pumpAndSettle();
      expect(find.text('1.250.000'), findsOneWidget);
      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(movements.creados.single.amount, 1250000);
    });

    testWidgets('guarda y vuelve a la pantalla anterior con SnackBar', (
      tester,
    ) async {
      usePhoneScreen(tester);
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
      usePhoneScreen(tester);
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
      usePhoneScreen(tester);
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
      usePhoneScreen(tester);
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
      usePhoneScreen(tester);
      movements.emit([buildExisting()]);
      await openEdit(tester);

      expect(find.text('Editar movimiento'), findsOneWidget);
      expect(find.text('45.000'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('10 feb 2026'), findsOneWidget);
      expect(find.text('Pasaje'), findsOneWidget);
    });

    testWidgets('actualiza en vez de crear', (tester) async {
      usePhoneScreen(tester);
      movements.emit([buildExisting()]);
      await openEdit(tester);

      await tester.enterText(find.widgetWithText(TextField, '45.000'), '50000');
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
      usePhoneScreen(tester);
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
      usePhoneScreen(tester);
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
      usePhoneScreen(tester);
      await openNew(tester);

      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.maxLength, 100);
    });

    testWidgets('el date picker no ofrece fechas futuras', (tester) async {
      usePhoneScreen(tester);
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
      expect(dialog.lastDate, DateTime(now.year, now.month, now.day));
    });
  });

  group('tildes y ñ', () {
    // La app es en español: si algún `inputFormatter` o validación se tragara
    // los caracteres acentuados, el usuario escribiría "Cafe" y "manana" sin
    // poder evitarlo. Estos tests lo fijan de punta a punta: se escribe con
    // acentos, se guarda y se comprueba lo que llegó al repositorio.
    const conTildes = 'Café con leche y jamón, añejado en Bogotá';

    testWidgets('la descripción acepta y guarda tildes, diéresis y ñ', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await openNew(tester);
      await fill(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Ej: almuerzo en la oficina'),
        conTildes,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(movements.creados, hasLength(1));
      expect(movements.creados.single.description, conTildes);
    });

    testWidgets('el texto acentuado se ve igual que el que no lo lleva', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await openNew(tester);

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Ej: almuerzo en la oficina'),
      );
      // El montant es el único campo filtrado: la descripción no puede
      // llevar `inputFormatters` ni un `textInputAction` que la recorte.
      expect(field.inputFormatters, isNull);
      expect(field.textCapitalization, TextCapitalization.sentences);

      await tester.enterText(
        find.widgetWithText(TextField, 'Ej: almuerzo en la oficina'),
        conTildes,
      );
      await tester.pumpAndSettle();

      expect(find.text(conTildes), findsOneWidget);
    });

    testWidgets('editar un movimiento con tildes las conserva', (tester) async {
      usePhoneScreen(tester);
      movements.emit([buildExisting(description: conTildes)]);
      await openEdit(tester);

      expect(find.text(conTildes), findsOneWidget);

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(movements.list.single.description, conTildes);
    });
  });

  /// El usuario pidió que el formulario se viera entero en una pantalla, sin
  /// scroll. Estos tests lo fijan: si alguien vuelve a agrandar los iconos o
  /// a subir el número de filas, fallan en vez de degradarse en silencio.
  group('el formulario entra en una pantalla', () {
    /// Las 12 categorías de gasto reales, que son el peor caso: con 4 de
    /// ingreso la rejilla es de una sola fila y no llega a apretar.
    List<Category> doceDeGasto() => List.generate(
      12,
      (i) => buildCategory(
        id: i + 1,
        name: 'Categoría ${i + 1}',
        type: MovementType.expense,
        sortOrder: i,
      ),
    );

    testWidgets('no hay scroll con las 12 categorías de gasto', (tester) async {
      usePhoneScreen(tester);
      categories = FakeCategoryRepository(doceDeGasto());
      await openNew(tester);

      final posicion = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(Scaffold),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;

      expect(
        posicion.maxScrollExtent,
        0,
        reason: 'el contenido no cabe en 360x800 y hay que hacer scroll',
      );
    });

    testWidgets('los campos de entrada quedan arriba y la rejilla debajo', (
      tester,
    ) async {
      usePhoneScreen(tester);
      categories = FakeCategoryRepository(doceDeGasto());
      await openNew(tester);

      double y(Finder f) => tester.getTopLeft(f).dy;

      // Orden pedido: monto, fecha y descripción primero; la rejilla de
      // iconos al final.
      expect(
        y(find.byType(AmountInputField)),
        lessThan(y(find.byType(DatePickerField))),
        reason: 'el monto debe ir antes que la fecha',
      );
      expect(
        y(find.byType(DatePickerField)),
        lessThan(
          y(find.widgetWithText(TextField, 'Ej: almuerzo en la oficina')),
        ),
        reason: 'la fecha debe ir antes que la descripción',
      );
      expect(
        y(find.widgetWithText(TextField, 'Ej: almuerzo en la oficina')),
        lessThan(y(find.byType(CategoryPicker))),
        reason: 'la rejilla de iconos va al final',
      );
    });

    testWidgets('el nombre de la categoría se pinta en color de texto', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await openNew(tester);

      final etiqueta = tester.widget<Text>(
        find.descendant(
          of: find.byType(CategoryPicker),
          matching: find.text('Comida'),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(CategoryPicker)));

      expect(
        etiqueta.style?.color,
        isNotNull,
        reason:
            'sin color explícito lo resuelve el ambiente y el nombre '
            'puede salir blanco sobre surface',
      );
      expect(etiqueta.style?.color, theme.colorScheme.onSurface);
    });
  });
}
