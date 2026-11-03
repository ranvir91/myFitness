import 'package:flutter/material.dart';

import '../../../core/constants/exercise_suggestions.dart';
import '../workout_provider.dart';

Future<void> showAddExerciseSheet(
  BuildContext context, {
  required WorkoutProvider provider,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddExerciseSheet(provider: provider),
  );
}

class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet({required this.provider});

  final WorkoutProvider provider;

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    widget.provider.addExercise(trimmed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = kExerciseSuggestions
        .where((e) => !widget.provider.customExercises.contains(e))
        .toList();

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
          Text('Add exercise', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Exercise name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: _add,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _add(_controller.text),
              child: const Text('Add'),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Suggestions', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _add(suggestion),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
