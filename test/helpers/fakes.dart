import 'dart:async';

import 'package:pipefinanzaspersonales/features/categories/domain/repositories/category_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/category.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/repositories/movement_repository.dart';

/// Fakes en memoria para probar `presentation` sin base de datos.
/// Se crean por secuencia según se necesitan, no todos de golpe.

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
  buildCategory(id: 2, name: 'Transporte', iconKey: 'directions_bus', sortOrder: 2),
  buildCategory(id: 3, name: 'Salario', type: MovementType.income, iconKey: 'work', sortOrder: 3),
];

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
  Stream<List<Category>> watchAll() async* {
    yield _categories;
    yield* _controller.stream;
  }

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

  @override
  Stream<List<Movement>> watchAll() async* {
    yield _movements;
    yield* _controller.stream;
  }

  @override
  Stream<List<Movement>> watchByMonth(DateTime month) => watchAll().map(
    (all) => all.where((m) => m.date.year == month.year && m.date.month == month.month).toList(growable: false),
  );

  @override
  Future<List<Movement>> getAll() async => _movements;

  @override
  Future<List<Movement>> getByMonth(DateTime month) async => _movements
      .where(
        (m) => m.date.year == month.year && m.date.month == month.month,
      )
      .toList(growable: false);

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
