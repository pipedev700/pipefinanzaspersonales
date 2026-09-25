import 'package:flutter/material.dart';

/// Placeholders de S00. Cada uno se sustituye por la pantalla real en su
/// secuencia (formulario en S04, historial en S05, dashboard en S06).
/// El router no cambia de forma: solo se reemplaza el `child` de cada ruta.

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Placeholder(title: 'Inicio', icon: Icons.dashboard_outlined);
}

class HistoryPlaceholder extends StatelessWidget {
  const HistoryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Placeholder(title: 'Historial', icon: Icons.history_outlined);
}

class MovementFormPlaceholder extends StatelessWidget {
  const MovementFormPlaceholder({this.id, super.key});

  final int? id;

  @override
  Widget build(BuildContext context) => _Placeholder(
    title: id == null ? 'Nuevo movimiento' : 'Editar movimiento',
    icon: Icons.edit_note,
  );
}
