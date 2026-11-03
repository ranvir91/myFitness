import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'exercise_detail_screen.dart';
import 'widgets/add_exercise_sheet.dart';
import 'widgets/add_routine_sheet.dart';
import 'widgets/log_entry_sheet.dart';
import 'widgets/log_routine_sheet.dart';
import 'workout_provider.dart';
import 'workout_settings_screen.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    if (!provider.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final exercises = provider.customExercises;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutSettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddExerciseSheet(context, provider: provider),
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's checklist", style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${provider.todayDoneCount} / ${exercises.length} done',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    'No exercises yet.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        showAddExerciseSheet(context, provider: provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add your first exercise'),
                  ),
                ],
              ),
            )
          else
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Column(
                children: [
                  for (final exercise in exercises)
                    _ExerciseChecklistTile(exercise: exercise, provider: provider),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Routines', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => showAddRoutineSheet(context, provider: provider),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (provider.routines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Group exercises into a routine to log them all at once.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...provider.routines.map(
              (routine) => Card(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: Text(routine.name),
                  subtitle: Text(routine.exercises.join(', ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => showLogRoutineSheet(
                          context,
                          provider: provider,
                          routine: routine,
                        ),
                        child: const Text('Log'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => provider.deleteRoutine(routine.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's log", style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${provider.todayTotalReps} reps total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.todaySets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No sets logged yet today.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...provider.todaySets.map(
              (s) => Dismissible(
                key: ValueKey(s.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) => provider.deleteSet(s.id),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text('${s.exercise} — ${s.reps} reps'),
                  subtitle: Text(DateFormat.jm().format(s.timestamp)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseChecklistTile extends StatelessWidget {
  const _ExerciseChecklistTile({required this.exercise, required this.provider});

  final String exercise;
  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    final done = provider.isDoneToday(exercise);
    final reps = provider.todayRepsFor(exercise);

    return ListTile(
      leading: Checkbox(
        value: done,
        onChanged: (checked) => _onToggle(context, checked ?? false),
      ),
      title: Text(exercise),
      subtitle: Text(done ? '$reps reps logged today' : 'Not logged yet'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
      ),
    );
  }

  Future<void> _onToggle(BuildContext context, bool checked) async {
    if (checked) {
      await showLogEntrySheet(context, provider: provider, exercise: exercise);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove today\'s log for $exercise?'),
        content: const Text('This deletes everything logged for this exercise today.'),
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
      await provider.clearTodayEntries(exercise);
    }
  }
}
