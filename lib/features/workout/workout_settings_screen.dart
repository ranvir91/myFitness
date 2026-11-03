import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/add_exercise_sheet.dart';
import 'workout_provider.dart';

class WorkoutSettingsScreen extends StatefulWidget {
  const WorkoutSettingsScreen({super.key});

  @override
  State<WorkoutSettingsScreen> createState() => _WorkoutSettingsScreenState();
}

class _WorkoutSettingsScreenState extends State<WorkoutSettingsScreen> {
  late double _goal;
  bool _goalInitialized = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    if (!_goalInitialized) {
      _goal = provider.dailyGoalReps.toDouble();
      _goalInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workout settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Daily rep goal', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Used to score your workout activity in Reports.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text('${_goal.round()} reps'),
          Slider(
            value: _goal,
            min: 10,
            max: 300,
            divisions: 29,
            label: '${_goal.round()} reps',
            onChanged: (v) => setState(() => _goal = v),
            onChangeEnd: (v) => provider.setDailyGoalReps(v.round()),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your exercises', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () =>
                    showAddExerciseSheet(context, provider: provider),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          if (provider.customExercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No exercises yet. Add one to start tracking.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...provider.customExercises.map(
              (exercise) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center),
                title: Text(exercise),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      _confirmRemoveExercise(context, provider, exercise),
                ),
              ),
            ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rep presets', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _addRepPreset(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Quick-select values shown when logging reps for any exercise.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in provider.repPresets)
                InputChip(
                  label: Text('$preset'),
                  onDeleted: () => provider.removeRepPreset(preset),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveExercise(
    BuildContext context,
    WorkoutProvider provider,
    String exercise,
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
    }
  }

  Future<void> _addRepPreset(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add rep preset'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'reps'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      await provider.addRepPreset(value);
    }
  }
}
