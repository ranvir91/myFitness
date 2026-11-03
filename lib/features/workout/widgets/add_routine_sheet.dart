import 'package:flutter/material.dart';

import '../workout_provider.dart';

Future<void> showAddRoutineSheet(
  BuildContext context, {
  required WorkoutProvider provider,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddRoutineSheet(provider: provider),
  );
}

class _AddRoutineSheet extends StatefulWidget {
  const _AddRoutineSheet({required this.provider});

  final WorkoutProvider provider;

  @override
  State<_AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<_AddRoutineSheet> {
  final _nameController = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty || _selected.isEmpty) return;
    widget.provider.addRoutine(_nameController.text, _selected.toList());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.provider.customExercises;

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
          Text('New routine', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Routine name',
              hintText: 'e.g. Leg Day',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          if (exercises.isEmpty)
            Text(
              'Add some exercises first before creating a routine.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            Text('Exercises', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final exercise in exercises)
                  FilterChip(
                    label: Text(exercise),
                    selected: _selected.contains(exercise),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selected.add(exercise);
                      } else {
                        _selected.remove(exercise);
                      }
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Create routine'),
            ),
          ),
        ],
      ),
    );
  }
}
