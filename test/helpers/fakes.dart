import 'dart:async';

import 'package:pipefinanzaspersonales/features/categories/domain/repositories/category_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/category.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/repositories/movement_repository.dart';

/// Fakes en memoria para probar `presentation` sin base de datos.
/// Se crean por secuencia según se necesitan, no todos de golpe.

/// Stream que entrega el estado actual y **después** todo lo que llegue.
///
/// La suscripción al [_controller] se abre **antes** de emitir el estado
/// actual, y no con un `async*` (`yield actual; yield* controller.stream`).
/// Un `StreamController.broadcast` descarta los eventos mientras no tiene
/// oyentes, y el generador `async*` solo entra en el `yield*` cuando el
/// consumidor pide el siguiente evento: entre la primera entrega y esa petición
/// hay una ventana en la que un `emit()` se pierde. Con Drift no pasa porque la
/// consulta ya está abierta cuando llega el valor, así que el fake debe
/// comportarse igual o los tests pasan por casualidad y fallan solos.
Stream<T> _replay<T>(StreamController<T> controller, T Function() current) {
  return Stream.multi((sink) {
    final subscription = controller.stream.listen(
      sink.add,
      onError: sink.addError,
    );
    sink.add(current());
    sink.onCancel = subscription.cancel;
  });
}

Category buildCategory({
  required int id,
  String? name,
  MovementType type = MovementType.expense,
  String iconKey = 'more_horiz',
  int colorValue = 0xFF64748B,
  int sortOrder = 0,
  bool isDefault = true,
}) => Category(
  id: id,
  name: name ?? 'Categoría $id',
  iconKey: iconKey,
  colorValue: colorValue,
  type: type,
  isDefault: isDefault,
  sortOrder: sortOrder,
);

/// Catálogo de pruebas: 2 gastos + 1 ingreso, en orden de `sortOrder`.
final testCategories = <Category>[
  buildCategory(id: 1, name: 'Comida', iconKey: 'restaurant', sortOrder: 1),
  buildCategory(
    id: 2,
    name: 'Transporte',
    iconKey: 'directions_bus',
    sortOrder: 2,
  ),
  buildCategory(
    id: 3,
    name: 'Salario',
    type: MovementType.income,
    iconKey: 'work',
    sortOrder: 3,
  ),
];

/// Constructor de movimientos de pruebas. `id` y `date` se pasan siempre
/// explícitos porque el orden del historial depende de ambos.
Movement buildMovement({
  required int id,
  required int amount,
  required DateTime date,
  MovementType type = MovementType.expense,
  int? categoryId,
  String description = '',
  String? categoryName,
}) {
  final catId = categoryId ?? (type.isIncome ? 3 : 1);
  return Movement(
    id: id,
    amount: amount,
    type: type,
    category: buildCategory(
      id: catId,
      name: categoryName ?? (type.isIncome ? 'Salario' : 'Comida'),
    ),
    date: date,
    description: description,
    createdAt: date,
    updatedAt: date,
  );
}

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([List<Category>? initial])
    : _categories = List.of(initial ?? testCategories);

  List<Category> _categories;
  final _controller = StreamController<List<Category>>.broadcast();

  /// Cambia el catálogo y notifica a los listeners, como haría la BD.
  void emit(List<Category> next) {
    _categories = List.of(next);
    _controller.add(_categories);
  }

  @override
  Stream<List<Category>> watchAll() => _replay(_controller, () => _categories);

  @override
  Future<List<Category>> getAll() async => _categories;

  @override
  Future<Category?> getById(int id) async {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> dispose() => _controller.close();
}

class FakeMovementRepository implements MovementRepository {
  FakeMovementRepository([List<Movement>? initial])
    : _movements = List.of(initial ?? const []);

  List<Movement> _movements;
  final _controller = StreamController<List<Movement>>.broadcast();
  int _nextId = 1000;

  /// Drafts enviados a `create`, en orden. Permite comprobar qué se habría
  /// escrito en la base sin inspeccionar la entidad mapeada.
  final creados = <MovementDraft>[];

  /// Movimientos actuales.
  List<Movement> get list => _movements;

  int get total => _movements.length;

  /// Reemplaza el contenido y notifica a los listeners, como haría la BD.
  void emit(List<Movement> next) {
    _movements = List.of(next);
    _controller.add(_movements);
  }

  /// Simula un fallo de la consulta, para probar el estado de error de la
  /// pantalla. El stream es broadcast, así que si nadie escucha el error se
  /// descarta en vez de quedar pendiente.
  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<List<Movement>> watchAll() => _replay(_controller, () => _movements);

  /// El DAO real filtra en SQL **y ordena `date DESC`**. El fake replica las
  /// dos cosas: si no, el historial en los tests saldría en orden distinto al
  /// de producción y los tests de agrupación pasarían por casualidad.
  List<Movement> _monthOf(DateTime month) {
    final filtered = _movements
        .where((m) => m.date.year == month.year && m.date.month == month.month)
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Stream<List<Movement>> watchByMonth(DateTime month) =>
      watchAll().map((_) => _monthOf(month));

  /// Réplica de `[start, end)`: el DAO real filtra en SQL y el fake en Dart,
  /// con el mismo criterio. Si no, los tests de la pantalla de histórico
  /// pasarían con rangos que en producción no devuelven nada.
  @override
  Stream<List<Movement>> watchByRange(DateTime start, DateTime end) =>
      watchAll().map(
        (movements) =>
            movements
                .where((m) => !m.date.isBefore(start) && m.date.isBefore(end))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date)),
      );

  @override
  Future<List<Movement>> getAll() async => _movements;

  @override
  Future<List<Movement>> getByMonth(DateTime month) async => _monthOf(month);

  @override
  Future<Movement?> getById(int id) async {
    for (final m in _movements) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Future<int> create(MovementDraft draft) async {
    creados.add(draft);
    final movement = Movement(
      id: _nextId++,
      amount: draft.amount,
      type: draft.type,
      category: buildCategory(id: draft.categoryId),
      date: draft.date,
      description: draft.description,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    _movements = [..._movements, movement];
    _controller.add(_movements);
    return movement.id;
  }

  @override
  Future<bool> update(int id, MovementDraft draft) async {
    final index = _movements.indexWhere((m) => m.id == id);
    if (index < 0) return false;
    _movements = [
      ..._movements.sublist(0, index),
      _movements[index].copyWith(
        amount: draft.amount,
        type: draft.type,
        category: buildCategory(id: draft.categoryId),
        date: draft.date,
        description: draft.description,
      ),
      ..._movements.sublist(index + 1),
    ];
    _controller.add(_movements);
    return true;
  }

  @override
  Future<void> delete(int id) async {
    _movements = _movements.where((m) => m.id != id).toList();
    _controller.add(_movements);
  }

  Future<void> dispose() => _controller.close();
}
