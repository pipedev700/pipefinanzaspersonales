import 'package:flutter/material.dart';

import 'app_colors.dart';

/// §21 — Colores con significado. Van en un ThemeExtension para que los
/// widgets no importen AppColors directamente.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.surfaceVariant,
  });

  final Color income;
  final Color expense;
  final Color warning;
  final Color surfaceVariant;

  static const light = SemanticColors(
    income: AppColors.income,
    expense: AppColors.expense,
    warning: AppColors.warning,
    surfaceVariant: AppColors.surfaceVariant,
  );

  /// Variante oscura: los semánticos suben de tono para mantener el contraste
  /// sobre `darkSurface`. Ver la nota de los `dark*` en `AppColors`.
  static const dark = SemanticColors(
    income: AppColors.darkIncome,
    expense: AppColors.darkExpense,
    warning: AppColors.darkWarning,
    surfaceVariant: AppColors.darkSurfaceVariant,
  );

  @override
  SemanticColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? surfaceVariant,
  }) {
    return SemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
    );
  }
}

extension SemanticColorsX on BuildContext {
  SemanticColors get semantic => Theme.of(this).extension<SemanticColors>()!;
}
