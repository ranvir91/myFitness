import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'profile_provider.dart';
import 'widgets/log_weight_sheet.dart';
import 'widgets/weight_trend_chart.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    if (!provider.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editDetails(context, provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogWeightSheet(context, provider: provider),
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          label: 'Current',
                          value: provider.currentWeightKg == null
                              ? '—'
                              : '${provider.currentWeightKg!.toStringAsFixed(1)} kg',
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          label: 'Goal',
                          value: provider.goalWeightKg == null
                              ? 'Not set'
                              : '${provider.goalWeightKg!.toStringAsFixed(1)} kg',
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          label: 'BMI',
                          value: provider.bmi == null
                              ? '—'
                              : provider.bmi!.toStringAsFixed(1),
                          sublabel: _bmiLabel(provider.bmiCategory),
                        ),
                      ),
                    ],
                  ),
                  if (provider.progressToGoal != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: provider.progressToGoal,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _progressLabel(provider),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Weight trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: WeightTrendChart(
                entries: provider.weightEntries,
                goalWeightKg: provider.goalWeightKg,
                color: Colors.purple,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (provider.weightEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No weight logged yet.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ...provider.weightEntries.reversed.map(
              (e) => Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: scheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) => provider.deleteEntry(e.id),
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                  subtitle: Text(DateFormat.yMMMd().format(e.timestamp)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _bmiLabel(BmiCategory? category) {
    return switch (category) {
      BmiCategory.underweight => 'Underweight',
      BmiCategory.normal => 'Normal',
      BmiCategory.overweight => 'Overweight',
      BmiCategory.obese => 'Obese',
      null => '',
    };
  }

  String _progressLabel(ProfileProvider provider) {
    final remaining = provider.remainingToGoal;
    if (remaining == null) return '';
    final progress = ((provider.progressToGoal ?? 0) * 100).round();
    if (remaining.abs() < 0.1) return 'Goal reached! 🎉';
    final verb = remaining > 0 ? 'to lose' : 'to gain';
    return '$progress% of the way there · ${remaining.abs().toStringAsFixed(1)} kg $verb';
  }

  Future<void> _editDetails(BuildContext context, ProfileProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditDetailsSheet(provider: provider),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value, this.sublabel});

  final String label;
  final String value;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          sublabel?.isNotEmpty == true ? sublabel! : label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _EditDetailsSheet extends StatefulWidget {
  const _EditDetailsSheet({required this.provider});

  final ProfileProvider provider;

  @override
  State<_EditDetailsSheet> createState() => _EditDetailsSheetState();
}

class _EditDetailsSheetState extends State<_EditDetailsSheet> {
  late final _ageController =
      TextEditingController(text: widget.provider.age?.toString() ?? '');
  late final _heightController =
      TextEditingController(text: widget.provider.heightCm?.toStringAsFixed(0) ?? '');
  late final _goalController = TextEditingController(
      text: widget.provider.goalWeightKg?.toStringAsFixed(1) ?? '');

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save() {
    final provider = widget.provider;
    provider.setAge(int.tryParse(_ageController.text.trim()));
    provider.setHeightCm(double.tryParse(_heightController.text.trim()));
    provider.setGoalWeightKg(double.tryParse(_goalController.text.trim()));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              suffixText: 'years',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Height',
              suffixText: 'cm',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Goal weight',
              suffixText: 'kg',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
