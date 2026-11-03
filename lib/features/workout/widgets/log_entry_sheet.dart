import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../workout_provider.dart';

/// Opens the "log reps" bottom sheet for [exercise]. Returns true if an
/// entry was saved.
Future<bool?> showLogEntrySheet(
  BuildContext context, {
  required WorkoutProvider provider,
  required String exercise,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LogEntrySheet(provider: provider, exercise: exercise),
  );
}

class _LogEntrySheet extends StatefulWidget {
  const _LogEntrySheet({required this.provider, required this.exercise});

  final WorkoutProvider provider;
  final String exercise;

  @override
  State<_LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<_LogEntrySheet> {
  DateTime _date = DateTime.now();
  int? _selectedReps;
  final _customRepsController = TextEditingController();

  @override
  void dispose() {
    _customRepsController.dispose();
    super.dispose();
  }

  int? get _reps {
    if (_customRepsController.text.trim().isNotEmpty) {
      return int.tryParse(_customRepsController.text.trim());
    }
    return _selectedReps;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    final reps = _reps;
    if (reps == null || reps <= 0) return;
    widget.provider.logEntry(
      exercise: widget.exercise,
      reps: reps,
      date: _date,
    );
    Navigator.of(context).pop(true);
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
          Text(
            'Log ${widget.exercise}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              isToday ? 'Today' : DateFormat.yMMMd().format(_date),
            ),
          ),
          const SizedBox(height: 16),
          Text('Reps', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in presets)
                ChoiceChip(
                  label: Text('$preset'),
                  selected: _selectedReps == preset &&
                      _customRepsController.text.trim().isEmpty,
                  onSelected: (_) => setState(() {
                    _selectedReps = preset;
                    _customRepsController.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customRepsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Custom reps',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _selectedReps = null),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _reps == null || _reps! <= 0 ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
