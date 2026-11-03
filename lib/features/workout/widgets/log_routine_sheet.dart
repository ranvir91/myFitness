import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/workout_routine.dart';
import '../workout_provider.dart';

Future<void> showLogRoutineSheet(
  BuildContext context, {
  required WorkoutProvider provider,
  required WorkoutRoutine routine,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LogRoutineSheet(provider: provider, routine: routine),
  );
}

class _LogRoutineSheet extends StatefulWidget {
  const _LogRoutineSheet({required this.provider, required this.routine});

  final WorkoutProvider provider;
  final WorkoutRoutine routine;

  @override
  State<_LogRoutineSheet> createState() => _LogRoutineSheetState();
}

class _LogRoutineSheetState extends State<_LogRoutineSheet> {
  DateTime _date = DateTime.now();
  final Map<String, int> _reps = {};

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (_reps.isEmpty) return;
    widget.provider.logRoutine(_reps, date: _date);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final presets = widget.provider.repPresets;
    final isToday = DateUtils.isSameDay(_date, DateTime.now());

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
          Text('Log ${widget.routine.name}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(isToday ? 'Today' : DateFormat.yMMMd().format(_date)),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final exercise in widget.routine.exercises) ...[
                    Text(exercise, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in presets)
                          ChoiceChip(
                            label: Text('$preset'),
                            selected: _reps[exercise] == preset,
                            onSelected: (_) =>
                                setState(() => _reps[exercise] = preset),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _reps.isEmpty ? null : _save,
              child: Text('Log ${_reps.length} / ${widget.routine.exercises.length} exercises'),
            ),
          ),
        ],
      ),
    );
  }
}
