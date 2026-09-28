import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // §16 — Solo vertical.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // El estilo de las barras del sistema **no** se fija aquí: con valores fijos
  // la barra de navegación quedaba blanca y con los iconos oscuros incluso en
  // modo oscuro. Lo calcula `PipeApp` a partir del tema, en un
  // `AnnotatedRegion`, y así sigue al tema en cada cambio.

  runApp(const ProviderScope(child: PipeApp()));
}
