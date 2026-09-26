import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'theme_extensions.dart';

abstract final class AppTheme {
  /// §33 — Tema claro.
  static ThemeData get light => _build(
    brightness: Brightness.light,
    brand: AppColors.brandBlue,
    onPrimary: AppColors.textOnPrimary,
    indicator: AppColors.brandLight,
    background: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    border: AppColors.border,
    divider: AppColors.divider,
    semantic: SemanticColors.light,
  );

  /// §33 — Tema oscuro. Misma estructura que el claro: los dos se construyen
  /// con [_build] y solo cambian los tokens, así que no pueden desincronizarse
  /// por olvidarse de updating uno al tocar el otro.
  ///
  /// Lo que cambia además de las superficies es el azul: `brandBlue` sobre
  /// fondo casi negro se queda en 3:1, así que el texto y los acentos usan
  /// `darkBrand` (6.9:1). Los botones rellenos **no**: ahí el color va de fondo
  /// y blanco encima, que con `darkBrand` daría 2.4:1. Ver la nota de
  /// `AppColors.darkBrand`.
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    brand: AppColors.darkBrand,
    // El azul claro del oscuro necesita texto oscuro encima, no blanco.
    onPrimary: AppColors.darkBackground,
    // La píldora del NavigationBar es el fondo de la etiqueta e icono del
    // destino activo, así que en oscuro va azul marino y no el azul claro del
    // tema claro: ahí la etiqueta clara encima sería ilegible.
    indicator: AppColors.brandNavy,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    border: AppColors.darkBorder,
    divider: AppColors.darkDivider,
    semantic: SemanticColors.dark,
  );

  /// §19 — Le pone color de texto a un estilo de la escala.
  ///
  /// Hace falta porque `AppTypography` son constantes **sin color**, a
  /// propósito: se reutilizan también sobre fondos de color. Al mapearlas
  /// tal cual sobre los slots del `textTheme` se perdía el color que
  /// Material deriva del `ColorScheme`, y el texto se quedaba con
  /// `color: null`. Un color `null` no es "negra": lo resuelve el ambiente, y
  /// en la app salía blanco sobre superficies blancas, ilegible.
  ///
  /// Los textos que van sobre fondo de color (botones, snackbar, appbar)
  /// declaran su color aparte y no pasan por aquí.
  static TextStyle _on(TextStyle style, Color color) =>
      style.copyWith(color: color);

  static ThemeData _build({
    required Brightness brightness,
    required Color brand,
    required Color onPrimary,
    required Color indicator,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color border,
    required Color divider,
    required SemanticColors semantic,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: brand,
            brightness: brightness,
          ).copyWith(
            primary: brand,
            onPrimary: onPrimary,
            surface: surface,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            error: semantic.expense,
            outlineVariant: border,
          ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      extensions: [semantic],
      textTheme: base.textTheme.copyWith(
        headlineLarge: _on(AppTypography.display, onSurface),
        headlineMedium: _on(AppTypography.display, onSurface),
        titleLarge: _on(AppTypography.title, onSurface),
        titleMedium: _on(AppTypography.title, onSurface),
        bodyLarge: _on(AppTypography.body, onSurface),
        bodyMedium: _on(AppTypography.body, onSurface),
        bodySmall: _on(AppTypography.caption, onSurface),
        labelLarge: _on(AppTypography.bodyStrong, onSurface),
        labelMedium: _on(AppTypography.label, onSurface),
        labelSmall: _on(AppTypography.caption, onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(brand, width: 2),
        errorBorder: _inputBorder(semantic.expense),
        focusedErrorBorder: _inputBorder(semantic.expense, width: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: indicator,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.textOnPrimary,
          textStyle: AppTypography.bodyStrong,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: AppTypography.label,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(color: surface),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppSpacing.radiusSm),
      ),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
