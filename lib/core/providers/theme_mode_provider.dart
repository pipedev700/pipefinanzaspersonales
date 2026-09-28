import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modo claro/oscuro elegido por el usuario.
///
/// Empieza en [ThemeMode.system]: si el sistema está en oscuro, la app se
/// pone oscura sin que nadie toque nada. El botón del AppBar es lo que
/// después fija el modo a mano.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Alterna a partir de lo que se ve ahora, no de [state].
  ///
  /// Importa porque en [ThemeMode.system] el modo "declarado" no es el que
  /// se está viendo: con el sistema en oscuro, [state] sigue siendo
  /// `system` mientras lo que hay en pantalla es oscuro. Si alternáramos
  /// sobre `state`, el primer toque en un sistema oscuro volvería a oscuro
  /// y parecería que el botón no hace nada.
  void toggle({required bool isDarkNow}) {
    state = isDarkNow ? ThemeMode.light : ThemeMode.dark;
  }

  /// Vuelve a seguir al sistema. Lo usa el gesto de mantener pulsado.
  void followSystem() => state = ThemeMode.system;
}
