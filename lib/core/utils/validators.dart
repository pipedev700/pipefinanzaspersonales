import 'amount_text_formatter.dart';

/// Resultado de una validación. Sin Flutter: son funciones puras y se
/// testean sin widget (§15, §32).
class ValidationResult {
  const ValidationResult.ok() : error = null;
  const ValidationResult.invalid(this.error);

  final String? error;
  bool get isValid => error == null;
}

/// Techo de seguridad. Un COP entero cabe de sobra en un `int` de 64 bits
/// (~9,2 * 10^18 pesos); el límite está para que un pegado accidental de un
/// número absurdo no se convierta en un error de SQLite.
const maxAmount = 999999999999;

/// Límite de la descripción (§15).
const maxDescriptionLength = 100;

/// §15 — Monto: entero de dígitos, mayor a cero.
///
/// El campo de entrada agrupa con puntos (`25.000`), así que el separador se
/// acepta; lo que no se acepta es nada más: ni signo, ni símbolo de moneda,
/// ni un punto que no sea separador de miles (`1.5` es un decimal mal escrito,
/// no un grupo de miles). La coma se rechaza explícitamente porque en `es_CO`
/// es el decimal. El entero sale de [parseAmountText].
ValidationResult validateAmount(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return const ValidationResult.invalid('Ingresa un monto');

  if (text.contains(',')) {
    return const ValidationResult.invalid('Ingresa un monto sin decimales');
  }
  if (!_groupedInteger.hasMatch(text)) {
    return const ValidationResult.invalid('Ingresa solo números');
  }

  final value = parseAmountText(text);
  if (value == null) {
    return const ValidationResult.invalid('Ingresa un monto');
  }
  if (value == 0) {
    return const ValidationResult.invalid('El monto debe ser mayor a cero');
  }
  if (value > maxAmount) {
    return const ValidationResult.invalid('El monto es demasiado grande');
  }
  return const ValidationResult.ok();
}

/// Un entero, ya sea pelado (`25000`) o con puntos de miles bien puestos
/// (`25.000`). Cubre a los dos lados del mismo formato: el validador acepta lo
/// que el campo produce, sin abrir la puerta a `-5000` ni a `1.5`.
final _groupedInteger = RegExp(r'^\d+(\.\d{3})*$');

/// §15 — Descripción: opcional, máximo 100 caracteres.
ValidationResult validateDescription(String? raw) {
  final text = (raw ?? '').trim();
  if (text.length > maxDescriptionLength) {
    return const ValidationResult.invalid(
      'Máximo $maxDescriptionLength caracteres',
    );
  }
  return const ValidationResult.ok();
}

/// §15 — No se permiten fechas futuras. `now` se inyecta para poder testear.
ValidationResult validateDate(DateTime? date, {DateTime? now}) {
  if (date == null) {
    return const ValidationResult.invalid('Selecciona una fecha');
  }

  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final selected = DateTime(date.year, date.month, date.day);

  if (selected.isAfter(today)) {
    return const ValidationResult.invalid('La fecha no puede ser futura');
  }
  return const ValidationResult.ok();
}

/// §15 — Valida el formulario completo. Devuelve el primer error, en el orden
/// en que aparecen los campos en pantalla: monto, categoría, fecha,
/// descripción.
///
/// `MovementFormState.firstError` delega aquí, así que la lista de reglas vive
/// en un solo sitio.
ValidationResult validateMovement({
  required String amount,
  required String description,
  required DateTime? date,
  required int? categoryId,
  DateTime? now,
}) {
  final checks = <ValidationResult>[
    validateAmount(amount),
    if (categoryId == null)
      const ValidationResult.invalid('Selecciona una categoría'),
    validateDate(date, now: now),
    validateDescription(description),
  ];

  for (final check in checks) {
    if (!check.isValid) return check;
  }
  return const ValidationResult.ok();
}
