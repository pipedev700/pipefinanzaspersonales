import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Espera el primer valor con tope de intentos, propagando el error si el
/// provider falla. Acotado a propósito: si nunca carga, el test falla con un
/// mensaje legible en vez de colgarse indefinidamente.
///
/// No usar `container.read(provider.future)`: eso espera la *siguiente*
/// emisión, y con un stream que ya emitió al suscribirse se queda esperando
/// una que no va a llegar.
Future<T> awaitFirstValue<T>(
  AsyncValue<T> Function() read, {
  String? description,
  int maxAttempts = 100,
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    final value = read();
    if (value.hasValue) return value.requireValue;
    if (value.hasError) throw value.error!;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timeout esperando: ${description ?? 'el primer valor del provider'}');
}

/// Igual que [awaitFirstValue], pero hasta que el valor **cumpla una
/// condición**. Necesario para esperar una *actualización*: el provider ya
/// tiene valor de la emisión anterior, así que [awaitFirstValue] devolvería
/// el viejo y el test comprobaría contra datos rancios.
Future<T> awaitValueWhere<T>(
  AsyncValue<T> Function() read,
  bool Function(T value) matches, {
  String? description,
  int maxAttempts = 100,
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    final value = read();
    if (value.hasError) throw value.error!;
    if (value.hasValue && matches(value.requireValue)) {
      return value.requireValue;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timeout esperando: ${description ?? 'un valor que cumpla la condición'}',
  );
}
