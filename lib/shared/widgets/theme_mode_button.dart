import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/theme_mode_provider.dart';

/// Botón del AppBar que alterna entre tema claro y oscuro.
///
/// El icono muestra el modo al que se va, no el actual: pulsar la luna
/// significa "ponlo oscuro", no "está oscuro". Es la convención que evita
/// tener que leer el icono como una pregunta.
///
/// Mantener pulsado devuelve el control al sistema, para deshacer el ajuste
/// manual.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkNow = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: isDarkNow ? 'Usar tema claro' : 'Usar tema oscuro',
      icon: Icon(isDarkNow ? Icons.light_mode : Icons.dark_mode),
      onPressed: () =>
          ref.read(themeModeProvider.notifier).toggle(isDarkNow: isDarkNow),
      onLongPress: () => ref.read(themeModeProvider.notifier).followSystem(),
    );
  }
}
