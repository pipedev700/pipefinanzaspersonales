import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/movement_type.dart';
import '../../domain/repositories/movement_repository.dart';

/// Estado del formulario. Los campos se guardan **crudos** (el monto como
/// texto) para que `TextField` no pierda el cursor al revalidar (§15).
class MovementFormState {
  const MovementFormState({
    this.id,
    this.amount = '',
    this.type = MovementType.expense,
    this.categoryId,
    this.date,
    this.description = '',
    this.isLoading = false,
    this.isSaving = false,
    this.saveError,
  });

  /// `null` = creando. Se llena al cargar el movimiento existente.
  final int? id;
  final String amount;
  final MovementType type;
  final int? categoryId;
  final DateTime? date;
  final String description;

  /// Solo en modo edición, mientras se lee el movimiento de la base. El botón
  /// de guardar se deshabilita para que nadie guarde antes de tiempo y se
  /// cree un duplicado en vez de actualizar.
  final bool isLoading;
  final bool isSaving;

  /// Error del último intento de guardado, o el primer error de validación.
  final String? saveError;

  bool get isEditing => id != null;

  /// Errores por campo, para pintarlos junto al input.
  String? amountError() => validateAmount(amount).error;
  String? dateError() => validateDate(date).error;
  String? descriptionError() => validateDescription(description).error;
  String? categoryError() =>
      categoryId == null ? 'Selecciona una categoría' : null;

  /// Primer error de todo el formulario, **en el orden en que aparecen los
  /// campos en pantalla**: monto, categoría, fecha, descripción.
  ///
  /// Delega en [validateMovement] para que no haya dos listas de reglas que
  /// se puedan desincronizar.
  String? get firstError => validateMovement(
    amount: amount,
    description: description,
    date: date,
    categoryId: categoryId,
  ).error;

  bool get isValid => firstError == null;

  MovementFormState copyWith({
    int? Function()? id,
    String? amount,
    MovementType? type,
    int? Function()? categoryId,
    DateTime? Function()? date,
    String? description,
    bool? isLoading,
    bool? isSaving,
    String? Function()? saveError,
  }) {
    return MovementFormState(
      id: id != null ? id() : this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      date: date != null ? date() : this.date,
      description: description ?? this.description,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError != null ? saveError() : this.saveError,
    );
  }
}

/// Controlador del formulario. **No** es `family`.
///
/// Riverpod 3.3.2 no tiene `FamilyNotifier` y `Notifier.build()` no recibe
/// argumento, así que un `NotifierProvider.family` hecho a mano no puede leer
/// el id. La alternativa es esta: un solo controlador y un `load(id)` explícito
/// que la pantalla llama en `initState`. Menos idiomático que una familia, pero
/// compila sin codegen y es más fácil de testear.
final movementFormProvider =
    NotifierProvider.autoDispose<MovementFormController, MovementFormState>(
      MovementFormController.new,
    );

class MovementFormController extends Notifier<MovementFormState> {
  @override
  MovementFormState build() {
    final now = DateTime.now();
    // Por defecto se crea un gasto de hoy (§12).
    return MovementFormState(date: DateTime(now.year, now.month, now.day));
  }

  /// Carga el movimiento a editar. `null` deja el formulario en modo creación.
  Future<void> load(int? id) async {
    if (id == null) {
      state = MovementFormState(date: _today());
      return;
    }

    state = state.copyWith(isLoading: true);
    final movement = await ref.read(movementRepositoryProvider).getById(id);

    if (movement == null) {
      // El id no existe (se borró en otro sitio). Se degrada a creación en
      // vez de dejar el formulario en un estado imposible de guardar.
      state = MovementFormState(date: _today());
      return;
    }

    state = MovementFormState(
      id: movement.id,
      amount: movement.amount.toString(),
      type: movement.type,
      categoryId: movement.category.id,
      date: movement.date,
      description: movement.description,
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setAmount(String value) =>
      state = state.copyWith(amount: value, saveError: () => null);

  /// Cambiar de tipo limpia la categoría: una categoría de gasto no aplica a
  /// un ingreso (§12).
  void setType(MovementType value) => state = state.copyWith(
    type: value,
    categoryId: () => null,
    saveError: () => null,
  );

  void setCategory(int? value) =>
      state = state.copyWith(categoryId: () => value, saveError: () => null);

  void setDate(DateTime value) =>
      state = state.copyWith(date: () => value, saveError: () => null);

  void setDescription(String value) =>
      state = state.copyWith(description: value, saveError: () => null);

  /// §15 — Valida y persiste. Devuelve `true` si tuvo éxito.
  Future<bool> save() async {
    if (state.isLoading) return false;

    final error = state.firstError;
    if (error != null) {
      state = state.copyWith(saveError: () => error);
      return false;
    }

    state = state.copyWith(isSaving: true, saveError: () => null);

    try {
      final draft = MovementDraft(
        amount: int.parse(state.amount.trim()),
        type: state.type,
        categoryId: state.categoryId!,
        date: state.date!,
        description: state.description,
      ).normalized();

      final repo = ref.read(movementRepositoryProvider);
      final id = state.id;
      if (id != null) {
        await repo.update(id, draft);
      } else {
        await repo.create(draft);
      }
      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      // Base llena, disco bloqueado, id que ya no existe: nunca se deja el
      // botón en un estado colgado.
      state = state.copyWith(
        isSaving: false,
        saveError: () => 'No se pudo guardar. Intenta de nuevo.',
      );
      return false;
    }
  }
}
