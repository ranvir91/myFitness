import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'workout_provider.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    if (!provider.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Rep Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ExercisePicker(provider: provider),
          const SizedBox(height: 24),
          _RepCounter(provider: provider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: provider.currentReps == 0
                    ? null
                    : provider.resetCounter,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed:
                    provider.currentReps == 0 ? null : provider.completeSet,
                icon: const Icon(Icons.check),
                label: const Text('Complete set'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's sets", style: Theme.of(context).textTheme.titleMedium),
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
                'No sets completed yet today.',
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

  void _openSettings(BuildContext context, WorkoutProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WorkoutSettingsSheet(provider: provider),
    );
  }
}

class _WorkoutSettingsSheet extends StatefulWidget {
  const _WorkoutSettingsSheet({required this.provider});

  final WorkoutProvider provider;

  @override
  State<_WorkoutSettingsSheet> createState() => _WorkoutSettingsSheetState();
}

class _WorkoutSettingsSheetState extends State<_WorkoutSettingsSheet> {
  late double _goal = widget.provider.dailyGoalReps.toDouble();

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workout settings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Daily rep goal: ${_goal.round()} reps'),
          Slider(
            value: _goal,
            min: 10,
            max: 300,
            divisions: 29,
            label: '${_goal.round()} reps',
            onChanged: (v) => setState(() => _goal = v),
            onChangeEnd: (v) => provider.setDailyGoalReps(v.round()),
          ),
        ],
      ),
    );
  }
}

class _ExercisePicker extends StatelessWidget {
  const _ExercisePicker({required this.provider});

  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final exercise in WorkoutProvider.defaultExercises)
          ChoiceChip(
            label: Text(exercise),
            selected: provider.currentExercise == exercise,
            onSelected: (_) => provider.setExercise(exercise),
          ),
      ],
    );
  }
}

class _RepCounter extends StatelessWidget {
  const _RepCounter({required this.provider});

  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: provider.increment,
        onLongPress: provider.decrement,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer,
            border: Border.all(color: scheme.primary, width: 3),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${provider.currentReps}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
              ),
              Text(
                'reps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to count · long-press to undo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
