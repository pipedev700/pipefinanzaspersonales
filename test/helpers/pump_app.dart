import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/core/providers/router_provider.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/widgets/category_filter_sheet.dart';

import 'fakes.dart';

/// Monta la app **entera** (router real, splash, pestañas) con los repositorios
/// falsos y deja abierta la pestaña [tab].
///
/// Devuelve el contenedor a propósito: las pantallas usan `context.push` al
/// formulario, así que hace falta un `GoRouter` de verdad, y para mover el
/// estado desde el test (rango, filtro) hace falta acceso al contenedor que
/// usa la app. Con un `ProviderScope` normal no se alcanza.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  required FakeMovementRepository movements,
  required FakeCategoryRepository categories,
  String? tab,
  Size size = const Size(1000, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      movementRepositoryProvider.overrideWithValue(movements),
      categoryRepositoryProvider.overrideWithValue(categories),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: container.read(appRouterProvider),
      ),
    ),
  );

  // El splash espera 1500 ms antes de saltar al dashboard.
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpAndSettle();

  if (tab != null) {
    // La etiqueta aparece dos veces (título del AppBar y destino del
    // `NavigationBar`); el último es el destino, que es el que hay que tocar.
    await tester.tap(find.text(tab).last);
    await tester.pumpAndSettle();
  }
  return container;
}

/// Un texto **dentro** de la hoja de filtro. El mismo nombre de categoría
/// puede estar también en una fila de la lista que hay detrás del modal, y sin
/// acotar el finder el test tocaría el elemento equivocado.
Finder inFilterSheet(String text) => find.descendant(
  of: find.byType(CategoryFilterSheet),
  matching: find.text(text),
);
