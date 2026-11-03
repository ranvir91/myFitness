import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'widgets/log_entry_sheet.dart';
import 'workout_provider.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final String exercise;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final entries = provider.entriesFor(exercise);
    final totalReps = entries.fold<int>(0, (sum, e) => sum + e.reps);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmRemoveExercise(context, provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showLogEntrySheet(context, provider: provider, exercise: exercise),
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                'No entries yet for $exercise.\nTap "Add entry" to log one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${entries.length} entries · $totalReps reps total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                ...entries.map(
                  (e) => Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) => provider.deleteSet(e.id),
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text('${e.reps} reps'),
                      subtitle: Text(DateFormat.yMMMd().add_jm().format(e.timestamp)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmRemoveExercise(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $exercise?'),
        content: const Text(
          'This deletes the exercise and all of its logged entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.removeExercise(exercise);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
