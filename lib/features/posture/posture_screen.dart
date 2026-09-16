import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/posture_check.dart';
import 'posture_provider.dart';

class PostureScreen extends StatelessWidget {
  const PostureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostureProvider>();

    if (!provider.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posture Check'),
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
          _PostureCard(provider: provider),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Good posture',
                  value: '${provider.todayGoodCount}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Adjusted',
                  value: '${provider.todayAdjustedCount}',
                  icon: Icons.self_improvement,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text("Today's checks", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (provider.todayChecks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No posture checks logged yet today.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...provider.todayChecks.map(
              (c) => Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) => provider.deleteCheck(c.id),
                child: ListTile(
                  leading: Icon(
                    c.status == PostureStatus.good
                        ? Icons.check_circle_outline
                        : Icons.self_improvement,
                    color: c.status == PostureStatus.good
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(
                    c.status == PostureStatus.good
                        ? 'Good posture'
                        : 'Adjusted posture',
                  ),
                  subtitle: Text(DateFormat.jm().format(c.timestamp)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context, PostureProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PostureSettingsSheet(provider: provider),
    );
  }
}

class _PostureCard extends StatelessWidget {
  const _PostureCard({required this.provider});

  final PostureProvider provider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.accessibility_new, size: 56),
            const SizedBox(height: 12),
            Text(
              'How is your posture right now?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => provider.logCheck(PostureStatus.good),
                  icon: const Icon(Icons.check),
                  label: const Text('Good'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => provider.logCheck(PostureStatus.adjusted),
                  icon: const Icon(Icons.self_improvement),
                  label: const Text('Adjusted'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PostureSettingsSheet extends StatefulWidget {
  const _PostureSettingsSheet({required this.provider});

  final PostureProvider provider;

  @override
  State<_PostureSettingsSheet> createState() => _PostureSettingsSheetState();
}

class _PostureSettingsSheetState extends State<_PostureSettingsSheet> {
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
          Text('Posture settings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Posture reminders'),
            subtitle: const Text('Get periodic nudges to check your posture'),
            value: provider.reminderEnabled,
            onChanged: (v) => provider.setReminderEnabled(v),
          ),
          if (provider.reminderEnabled) ...[
            Text('Every ${_interval.round()} minutes'),
            Slider(
              value: _interval,
              min: 15,
              max: 120,
              divisions: 21,
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
