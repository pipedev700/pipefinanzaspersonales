import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/database/seed/default_categories.dart';
import 'package:pipefinanzaspersonales/features/categories/presentation/category_icon_registry.dart';
import 'package:pipefinanzaspersonales/features/categories/presentation/widgets/category_icon.dart';

import '../helpers/fakes.dart';

void main() {
  group('CategoryIconRegistry', () {
    test('resuelve las claves conocidas', () {
      expect(CategoryIconRegistry.resolve('restaurant'), Icons.restaurant);
      expect(CategoryIconRegistry.resolve('work'), Icons.work);
      expect(CategoryIconRegistry.resolve('more_horiz'), Icons.more_horiz);
    });

    test('la huella de mascotas y la inversión tienen glifo propio', () {
      expect(CategoryIconRegistry.resolve('pets'), Icons.pets);
      expect(
        CategoryIconRegistry.resolve('savings_outlined'),
        Icons.savings_outlined,
      );
    });

    test('una clave desconocida cae al icono genérico, no lanza', () {
      expect(CategoryIconRegistry.resolve('no_existe'), Icons.category);
      expect(CategoryIconRegistry.resolve(''), Icons.category);
    });

    test('has() distingue una clave real de la genérica', () {
      expect(CategoryIconRegistry.has('restaurant'), isTrue);
      expect(CategoryIconRegistry.has('no_existe'), isFalse);
    });

    // Este es el test que importa: si una `iconKey` de la semilla tiene un
    // typo, todas las categorías se degradan a `Icons.category` y **ningún**
    // otro test falla, porque el fallback es legal por diseño.
    test('todas las categorías de la semilla tienen icono propio', () {
      final sinIcono = defaultCategories
          .where((c) => !CategoryIconRegistry.has(c.iconKey))
          .map((c) => '${c.name} -> ${c.iconKey}')
          .toList();

      expect(
        sinIcono,
        isEmpty,
        reason: 'Estas categorías caerían al icono genérico: $sinIcono',
      );
    });

    test('el registro no tiene claves huérfanas', () {
      final huerfanas = CategoryIconRegistry.keys
          .where((k) => !defaultCategories.any((c) => c.iconKey == k))
          .toList();
      expect(huerfanas, isEmpty, reason: 'Claves sin usar: $huerfanas');
    });

    test('ninguna categoría del seed usa la clave genérica', () {
      // Si alguien secciona la clave, el ítem se vería sin identidad visual.
      expect(defaultCategories.any((c) => c.iconKey == 'no_existe'), isFalse);
    });
  });

  group('CategoryIcon', () {
    testWidgets('pinta el icono con el color de la categoría', (tester) async {
      final category = buildCategory(
        id: 1,
        name: 'Comida',
        iconKey: 'restaurant',
        colorValue: 0xFFF97316,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryIcon(category: category)),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CategoryIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      // Fondo al 12% de opacidad del color de la categoría.
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color!.a, closeTo(0.12, 0.001));
    });

    testWidgets('el tamaño por defecto es 44 y el icono la mitad', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryIcon(category: buildCategory(id: 1))),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CategoryIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints!.maxWidth, 44);
      expect(tester.widget<Icon>(find.byType(Icon)).size, 22);
    });

    testWidgets('respeta un tamaño explícito', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIcon(category: buildCategory(id: 1), size: 60),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CategoryIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints!.maxWidth, 60);
      expect(tester.widget<Icon>(find.byType(Icon)).size, 30);
    });

    testWidgets('una clave inválida no rompe el render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: buildCategory(id: 1, iconKey: 'no_existe'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expone el nombre de la categoría como etiqueta accesible', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: buildCategory(id: 1, name: 'Alimentación'),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Alimentación'), findsOneWidget);
    });
  });
}
