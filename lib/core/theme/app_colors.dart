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
}
