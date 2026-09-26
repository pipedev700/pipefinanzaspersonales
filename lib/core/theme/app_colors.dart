import 'package:flutter/material.dart';

/// §19 — Única fuente de verdad del color. Ningún otro archivo
/// define colores ni hex literales.
abstract final class AppColors {
  // Marca
  static const brandBlue = Color(0xFF2563EB);
  static const brandNavy = Color(0xFF1E3A5F);
  static const brandLight = Color(0xFFDBEAFE);

  // Superficies
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);

  // Texto
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Semánticos
  static const income = Color(0xFF16A34A);
  static const expense = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);

  // Bordes
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFCBD5E1);

  // Superficies y texto en modo oscuro (§33)
  //
  // Los semánticos de abajo son un tono más claro que los de arriba: los
  // mismos verdes y rojos sobre un fondo casi negro no llegan al contraste
  // mínimo, y el verde y el rojo de las cifras del balance son justo lo que
  // el usuario mira para saber si entrou o salio dinero.
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceVariant = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkBorder = Color(0xFF334155);
  static const darkDivider = Color(0xFF475569);
  static const darkIncome = Color(0xFF4ADE80);
  static const darkExpense = Color(0xFFF87171);
  static const darkWarning = Color(0xFFFBBF24);

  /// Azul de marca para texto y acentos en oscuro. El `brandBlue` de los
  /// botones queda en 3:1 sobre el fondo oscuro, por debajo del 4.5:1 que pide
  /// WCAG AA para texto normal. Este da 6.9:1.
  ///
  /// Solo para texto, bordes y acentos: los botones rellenos siguen usando
  /// `brandBlue`, porque blanco sobre este azul solo daría 2.4:1.
  static const darkBrand = Color(0xFF60A5FA);
}
