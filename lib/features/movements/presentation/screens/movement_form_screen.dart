import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../providers/movement_form_controller.dart';
import '../widgets/amount_input_field.dart';
import '../widgets/category_picker.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/movement_type_selector.dart';

/// §12 — Crear y editar comparten pantalla. `id == null` → crear.
class MovementFormScreen extends ConsumerStatefulWidget {
  const MovementFormScreen({this.id, super.key});

  final int? id;

  @override
  ConsumerState<MovementFormScreen> createState() =>
      _MovementFormScreenState();
}

class _MovementFormScreenState extends ConsumerState<MovementFormScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();

  /// Si los `TextEditingController` ya se rellenaron con los datos del
  /// movimiento. Evita que cada rebuild sobrescriba lo que el usuario está
  /// escribiendo y le mueva el cursor.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    // Riverpod 3 no entrega el id de la ruta al `build` de un Notifier
    // (ver §S04), así que la carga es explícita.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(movementFormProvider.notifier).load(widget.id);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Copia el estado del provider a los controllers **una sola vez**, cuando
  /// llegan los datos del movimiento a editar.
  void _seedIfNeeded(MovementFormState state) {
    if (_seeded || state.id == null) return;
    _seeded = true;
    _amount.text = state.amount;
    _description.text = state.description;
  }

  /// El error de categoría ya se pinta bajo el grid, así que el bloque
  /// genérico del final lo repetiría por pantalla. Solo se muestra cuando el
  /// error es de otro campo o de guardado.
  bool _showSaveError(MovementFormState state) {
    final error = state.saveError;
    if (error == null) return false;
    return error != state.categoryError();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movementFormProvider);
    _seedIfNeeded(state);

    final categories = ref.watch(
      state.type.isExpense ? expenseCategoriesProvider : incomeCategoriesProvider,
    );
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? 'Editar movimiento' : 'Nuevo movimiento'),
        actions: [
          if (state.isEditing)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              onPressed: () => _confirmDelete(state.id!),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          MovementTypeSelector(
            value: state.type,
            onChanged: ref.read(movementFormProvider.notifier).setType,
          ),
          const SizedBox(height: AppSpacing.lg),
          AmountInputField(
            controller: _amount,
            onChanged: ref.read(movementFormProvider.notifier).setAmount,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Categoría', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          categories.isEmpty
              ? const _CategoryLoading()
              : CategoryPicker(
                  categories: categories,
                  selectedId: state.categoryId,
                  onChanged: ref.read(movementFormProvider.notifier).setCategory,
                ),
          // El error de categoría solo aparece tras intentar guardar: en
          // una pantalla recién abierta sería ruido, no ayuda (§15).
          if (state.saveError != null && state.categoryError() != null)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.sm,
              ),
              child: Text(
                state.categoryError()!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          DatePickerField(
            value: state.date,
            errorText: state.dateError(),
            onChanged: ref.read(movementFormProvider.notifier).setDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _description,
            onChanged: ref.read(movementFormProvider.notifier).setDescription,
            maxLength: maxDescriptionLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText: 'Ej: almuerzo en la oficina',
              errorText: state.descriptionError(),
            ),
          ),
          if (_showSaveError(state)) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.saveError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          // Empuja el contenido para que el teclado no tape el botón.
          SizedBox(height: bottomInset > 0 ? bottomInset : AppSpacing.lg),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: FilledButton(
            // Deshabilitado mientras carga o guarda: evita doble guardado y
            // crear un duplicado en vez de actualizar.
            onPressed: state.isLoading || state.isSaving ? null : _save,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(state.isEditing ? 'Guardar cambios' : 'Guardar'),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final ok = await ref.read(movementFormProvider.notifier).save();
    if (!ok || !mounted) return;

    final wasEditing = ref.read(movementFormProvider).isEditing;
    context.pop();
    showAppSnackBar(
      context,
      wasEditing ? 'Movimiento actualizado' : 'Movimiento registrado',
      wasEditing ? SnackBarKind.info : SnackBarKind.success,
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar movimiento',
      message: 'Se eliminará de forma permanente. ¿Continuar?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(movementRepositoryProvider).delete(id);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'No se pudo eliminar',
          SnackBarKind.error,
        );
      }
      return;
    }

    if (!mounted) return;
    context.pop();
    showAppSnackBar(context, 'Movimiento eliminado', SnackBarKind.info);
  }
}

/// Estado de carga del grid de categorías.
class _CategoryLoading extends StatelessWidget {
  const _CategoryLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Text(
          'Cargando categorías…',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
