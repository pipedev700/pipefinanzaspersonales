import 'package:flutter/material.dart';

/// D9 — Convierte la clave textual guardada en la BD a un `IconData` de
/// Material.
///
/// Las claves viven en el dominio como `String` (nunca como codepoints) para
/// que `domain` no dependa de Flutter. Este es el único punto donde se
/// resuelven.
abstract final class CategoryIconRegistry {
  static const _icons = <String, IconData>{
    // Gastos
    'restaurant': Icons.restaurant,
    'directions_bus': Icons.directions_bus,
    'home': Icons.home,
    'bolt': Icons.bolt,
    'favorite': Icons.favorite,
    'movie': Icons.movie,
    'school': Icons.school,
    'shopping_bag': Icons.shopping_bag,
    'devices': Icons.devices,
    // Ingresos
    'work': Icons.work,
    'laptop_mac': Icons.laptop_mac,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    // Común
    'more_horiz': Icons.more_horiz,
  };

  /// Icono de respaldo. Una clave desconocida **no** lanza: la categoría se
  /// sigue pintando, solo que con el glifo genérico.
  static IconData resolve(String key) => _icons[key] ?? Icons.category;

  /// `true` si la clave tiene icono propio. Lo usan los tests para detectar
  /// typos en la semilla: sin esto, un `iconKey` mal escrito degrada los 14
  /// iconos a `Icons.category` sin que nada falle.
  static bool has(String key) => _icons.containsKey(key);

  /// Todas las claves con icono propio. Para tests y para la documentación.
  static Iterable<String> get keys => _icons.keys;
}
