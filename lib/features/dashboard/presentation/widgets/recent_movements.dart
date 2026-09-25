import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../movements/domain/entities/movement.dart';
import '../../../movements/presentation/widgets/movement_tile.dart';

/// §13 — Los 5 movimientos más recientes del mes.
class RecentMovements extends StatelessWidget {
  const RecentMovements({required this.movements, super.key});

  final List<Movement> movements;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Text(
              'Movimientos recientes',
              style: theme.textTheme.titleMedium,
            ),
          ),
          for (final m in movements)
            MovementTile(
              movement: m,
              onTap: () =>
                  context.push(AppRoutes.editMovementPath(m.id.toString())),
            ),
        ],
      ),
    );
  }
}
