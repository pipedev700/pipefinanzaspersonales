import '../entities/movement.dart';
import '../entities/movement_type.dart';

/// Datos de entrada para crear o editar. Sin `id`: es un movimiento nuevo.
/// Existe para que la capa de presentación nunca construya un `Companion`
/// de Drift.
class MovementDraft {
  const MovementDraft({
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.description,
  });

  /// Entero positivo (D6): el signo lo determina `type`.
  final int amount;
  final MovementType type;
  final int categoryId;
  final DateTime date;
  final String description;

  /// Normaliza antes de persistir: monto absoluto, descripción recortada y
  /// fecha a medianoche local.
  MovementDraft normalized() => MovementDraft(
    amount: amount.abs(),
    type: type,
    categoryId: categoryId,
    date: DateTime(date.year, date.month, date.day),
    description: description.trim(),
  );
}

/// Contrato del repositorio. La capa `data` lo implementa; `presentation`
/// depende solo de esta interfaz (§27).
abstract interface class MovementRepository {
  Stream<List<Movement>> watchAll();

  /// D12 — Filtra el rango de fechas en la consulta; los cálculos van en Dart.
  Stream<List<Movement>> watchByMonth(DateTime month);

  /// Intervalo `[start, end)` para la pantalla de histórico. A diferencia de
  /// [watchByMonth] el rango lo elige el usuario, así que entra por
  /// parámetro. [end] es **excluido**: se pasa el día siguiente al último
  /// seleccionado.
  Stream<List<Movement>> watchByRange(DateTime start, DateTime end);

  Future<List<Movement>> getByMonth(DateTime month);
  Future<List<Movement>> getAll();
  Future<Movement?> getById(int id);
  Future<int> create(MovementDraft draft);
  Future<bool> update(int id, MovementDraft draft);
  Future<void> delete(int id);
}
