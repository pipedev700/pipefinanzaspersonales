import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'theme_extensions.dart';

abstract final class AppTheme {
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
  static TextStyle _on(TextStyle style) =>
      style.copyWith(color: AppColors.textPrimary);

  /// Solo se implementa el tema claro (§33). Los tokens quedan
  /// centralizados para poder añadir dark sin reescribir widgets.
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandBlue,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.brandBlue,
        onPrimary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.expense,
        outlineVariant: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      extensions: const [SemanticColors.light],
      textTheme: base.textTheme.copyWith(
        headlineLarge: _on(AppTypography.display),
        headlineMedium: _on(AppTypography.display),
        titleLarge: _on(AppTypography.title),
        titleMedium: _on(AppTypography.title),
        bodyLarge: _on(AppTypography.body),
        bodyMedium: _on(AppTypography.body),
        bodySmall: _on(AppTypography.caption),
        labelLarge: _on(AppTypography.bodyStrong),
        labelMedium: _on(AppTypography.label),
        labelSmall: _on(AppTypography.caption),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusSm),
          ),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusSm),
          ),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusSm),
          ),
          borderSide: BorderSide(color: AppColors.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusSm),
          ),
          borderSide: BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusSm),
          ),
          borderSide: BorderSide(color: AppColors.expense, width: 2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandLight,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusMd),
          ),
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
          foregroundColor: AppColors.brandBlue,
          textStyle: AppTypography.label,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: AppColors.textOnPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}
