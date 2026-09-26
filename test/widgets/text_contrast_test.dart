import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/core/theme/app_colors.dart';
import 'package:pipefinanzaspersonales/core/theme/app_theme.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/history_screen.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/movement_form_screen.dart';

import '../helpers/fakes.dart';

/// Guarda global de contraste del texto.
///
/// El bug que persiguió esta suite era de familia: varios textos usaban
/// `AppTypography` (constantes sin color) o slots del `textTheme` a los que
/// el tema les había quitado el color, y quedaban con `color: null`. Un color
/// `null` no es negro: lo resuelve el ambiente, y en la app salía **blanco
/// sobre superficie blanca**.
///
/// En vez de fijar texto a texto, esto recorre los `RenderParagraph` ya
/// pintados de cada pantalla y exige que todos tengan un color resuelto y
/// contraste suficiente contra el fondo sobre el que se pintan. Un texto
/// nuevo sin color se detecta aquí, sin que nadie lo note en el dispositivo.
void main() {
  late FakeMovementRepository movements;
  late FakeCategoryRepository categories;
  late GoRouter router;

  setUp(() {
    movements = FakeMovementRepository([
      buildMovement(
        id: 1,
        amount: 45000,
        date: DateTime(2026, 3, 10),
        type: MovementType.expense,
        description: 'Almuerzo en la oficina',
      ),
      buildMovement(
        id: 2,
        amount: 3000000,
        date: DateTime(2026, 3, 1),
        type: MovementType.income,
        description: 'Salario de marzo',
      ),
      // Sin descripción: la fila cae al nombre de la categoría como título.
      buildMovement(
        id: 3,
        amount: 12000,
        date: DateTime(2026, 3, 12),
        type: MovementType.expense,
        description: '',
      ),
    ]);
    categories = FakeCategoryRepository([
      buildCategory(id: 1, name: 'Comida', iconKey: 'restaurant'),
      buildCategory(id: 2, name: 'Transporte', iconKey: 'directions_bus'),
      buildCategory(id: 3, name: 'Salario', type: MovementType.income),
    ]);
    router = GoRouter(
      initialLocation: '/historial',
      routes: [
        GoRoute(
          path: '/historial',
          builder: (_, _) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/nuevo',
          builder: (_, _) => const MovementFormScreen(),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await movements.dispose();
    await categories.dispose();
  });

  /// Monta la pantalla y comprueba cada párrafo que se ha pintado.
  ///
  /// Solo se miran los que están en pantalla: un `ListView` no construye lo
  /// que queda fuera del viewport, y lo que no se pintó no se puede medir.
  ///
  /// [theme] es lo que hace que esta guarda sirva también para el modo
  /// oscuro: un widget que se quede con un color claro fijo sale aquí, y no
  /// hace falta probarlo a mano en un dispositivo.
  Future<void> comprobarContraste(
    WidgetTester tester, {
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movementRepositoryProvider.overrideWithValue(movements),
          categoryRepositoryProvider.overrideWithValue(categories),
        ],
        child: MaterialApp.router(theme: theme, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final parrafos = find
        .byType(RichText)
        .evaluate()
        .where((e) => e.renderObject is RenderParagraph)
        .toList();

    expect(parrafos, isNotEmpty, reason: 'la pantalla no pintó ningún texto');

    final sinColor = <String>[];
    final sinContraste = <String>[];

    for (final elemento in parrafos) {
      final p = elemento.renderObject as RenderParagraph;
      final texto = p.text.toPlainText().trim();
      if (texto.isEmpty) continue;

      final color = p.text.style?.color;
      if (color == null) {
        sinColor.add(texto);
        continue;
      }

      // Fondo real del párrafo: el ancestro compuesto más cercano.
      final fondo = _fondoDe(elemento, theme.colorScheme.surface);
      if (_contraste(color, fondo) < 3.0) {
        sinContraste.add('"$texto" ${_hex(color)} sobre ${_hex(fondo)}');
      }
    }

    expect(
      sinColor,
      isEmpty,
      reason: 'texto con color null, lo resuelve el ambiente: $sinColor',
    );
    expect(
      sinContraste,
      isEmpty,
      reason: 'texto sin contraste legible: $sinContraste',
    );
  }

  void usarTelefono(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('historial claro: ningún texto sin color ni sin contraste',
      (tester) async {
    usarTelefono(tester);
    await comprobarContraste(tester, theme: AppTheme.light);
  });

  testWidgets('formulario claro: ningún texto sin color ni sin contraste',
      (tester) async {
    usarTelefono(tester);
    router.go('/nuevo');
    await comprobarContraste(tester, theme: AppTheme.light);
  });

  testWidgets('historial oscuro: ningún texto sin color ni sin contraste',
      (tester) async {
    usarTelefono(tester);
    await comprobarContraste(tester, theme: AppTheme.dark);
  });

  testWidgets('formulario oscuro: ningún texto sin color ni sin contraste',
      (tester) async {
    usarTelefono(tester);
    router.go('/nuevo');
    await comprobarContraste(tester, theme: AppTheme.dark);
  });

  testWidgets('el texto del tema ya trae color, no null', (tester) async {
    final theme = AppTheme.light;
    final slots = <String, TextStyle?>{
      'headlineLarge': theme.textTheme.headlineLarge,
      'headlineMedium': theme.textTheme.headlineMedium,
      'titleLarge': theme.textTheme.titleLarge,
      'titleMedium': theme.textTheme.titleMedium,
      'bodyLarge': theme.textTheme.bodyLarge,
      'bodyMedium': theme.textTheme.bodyMedium,
      'bodySmall': theme.textTheme.bodySmall,
      'labelLarge': theme.textTheme.labelLarge,
      'labelMedium': theme.textTheme.labelMedium,
      'labelSmall': theme.textTheme.labelSmall,
    };

    for (final entrada in slots.entries) {
      expect(
        entrada.value?.color,
        AppColors.textPrimary,
        reason: 'el slot ${entrada.key} del tema no quedó en color de texto',
      );
    }
  });
}

/// Sube por el árbol buscando el fondo **opaco** más cercano, que es lo que
/// el usuario ve detrás del texto.
///
/// Se mira `ColoredBox` y `Material` porque cada uno pinta fondos distintos:
/// las surfaces y campos usan `ColoredBox`, y los botones (que llevan texto
/// blanco sobre azul) usan un `Material` propio. Con solo uno de los dos, el
/// texto de los botones parecía blanco sobre blanco.
///
/// Los transparentes se saltan: hay `ColoredBox` con alpha 0 en el árbol (los
/// de `Tooltip`, por ejemplo) y quedarse con el primero hacía creer que el
/// texto estaba sobre negro.
Color _fondoDe(Element elemento, Color porDefecto) {
  Color? encontrado;
  elemento.visitAncestorElements((ancestro) {
    final widget = ancestro.widget;
    final color = switch (widget) {
      ColoredBox(color: final c) => c,
      Material(color: final c?) => c,
      _ => null,
    };
    if (color != null && color.a > 0.5) {
      encontrado = color;
      return false;
    }
    return true;
  });
  return encontrado ?? porDefecto;
}

double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

String _hex(Color c) =>
    '#${(c.r * 255).round().toRadixString(16).padLeft(2, '0')}'
    '${(c.g * 255).round().toRadixString(16).padLeft(2, '0')}'
    '${(c.b * 255).round().toRadixString(16).padLeft(2, '0')}';
