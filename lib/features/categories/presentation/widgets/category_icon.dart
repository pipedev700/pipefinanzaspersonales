import 'package:flutter/material.dart';

import '../../../movements/domain/entities/category.dart';
import '../category_icon_registry.dart';

/// §12 — Ícono circular con el color de la categoría.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({required this.category, this.size = 44, super.key});

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CategoryIconRegistry.resolve(category.iconKey),
        size: size * 0.5,
        color: color,
        semanticLabel: category.name,
      ),
    );
  }
}
