import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'hydration_provider.dart';
import 'widgets/hydration_progress_ring.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  static const _quickAmounts = [100, 200, 300, 500];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HydrationProvider>();

    if (!provider.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration'),
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
          Center(
            child: HydrationProgressRing(
              progress: provider.progress,
              currentMl: provider.todayTotalMl,
              goalMl: provider.goalMl,
            ),
          ),
          const SizedBox(height: 8),
          if (provider.streakDays > 0)
            Center(
              child: Chip(
                avatar: const Icon(Icons.local_fire_department, size: 18),
                label: Text('${provider.streakDays}-day streak'),
              ),
            ),
          const SizedBox(height: 24),
          Text('Quick add', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final amount in _quickAmounts)
                _QuickAddButton(amountMl: amount, provider: provider),
              _CustomAddButton(provider: provider),
            ],
          ),
          const SizedBox(height: 28),
          Text("Today's log", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (provider.todayEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No drinks logged yet today.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...provider.todayEntries.map(
              (e) => Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) => provider.removeEntry(e.id),
                child: ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text('${e.amountMl} ml'),
                  subtitle: Text(DateFormat.jm().format(e.timestamp)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context, HydrationProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HydrationSettingsSheet(provider: provider),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.amountMl, required this.provider});

  final int amountMl;
  final HydrationProvider provider;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {
        provider.addDrink(amountMl);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Added $amountMl ml'),
            duration: const Duration(seconds: 1),
          ));
      },
      icon: const Icon(Icons.add),
      label: Text('$amountMl ml'),
    );
  }
}

class _CustomAddButton extends StatelessWidget {
  const _CustomAddButton({required this.provider});

  final HydrationProvider provider;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final amount = await _promptAmount(context);
        if (amount != null && amount > 0) {
          provider.addDrink(amount);
        }
      },
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Custom'),
    );
  }

  Future<int?> _promptAmount(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add custom amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.of(context).pop(value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _HydrationSettingsSheet extends StatefulWidget {
  const _HydrationSettingsSheet({required this.provider});

  final HydrationProvider provider;

  @override
  State<_HydrationSettingsSheet> createState() =>
      _HydrationSettingsSheetState();
}

class _HydrationSettingsSheetState extends State<_HydrationSettingsSheet> {
  late double _goal = widget.provider.goalMl.toDouble();
  late double _interval = widget.provider.reminderIntervalMinutes.toDouble();

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
          Text('Hydration settings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Daily goal: ${_goal.round()} ml'),
          Slider(
            value: _goal,
            min: 500,
            max: 5000,
            divisions: 45,
            label: '${_goal.round()} ml',
            onChanged: (v) => setState(() => _goal = v),
            onChangeEnd: (v) => provider.setGoal(v.round()),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Drink reminders'),
            subtitle: const Text('Get notified to drink water periodically'),
            value: provider.reminderEnabled,
            onChanged: (v) => provider.setReminderEnabled(v),
          ),
          if (provider.reminderEnabled) ...[
            Text('Every ${_interval.round()} minutes'),
            Slider(
              value: _interval,
              min: 15,
              max: 180,
              divisions: 33,
              label: '${_interval.round()} min',
              onChanged: (v) => setState(() => _interval = v),
              onChangeEnd: (v) => provider.setReminderInterval(v.round()),
            ),
          ],
        ],
      ),
    );
  }
}
