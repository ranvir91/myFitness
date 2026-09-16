import 'package:flutter/material.dart';

import '../report_engine.dart';
import 'mini_bar_chart.dart';
import 'verdict_badge.dart';

class ModuleReportCard extends StatelessWidget {
  const ModuleReportCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.report,
    required this.labels,
    required this.activityNoun,
  });

  final String title;
  final IconData icon;
  final Color color;
  final ModuleReport report;
  final List<String> labels;

  /// e.g. "days logged" — used in the "N of M {activityNoun}" stat line.
  final String activityNoun;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                VerdictBadge(verdict: report.verdict),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${report.activeUnits} of ${report.totalUnits} $activityNoun · avg score ${report.averageScore.round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            MiniBarChart(values: report.buckets, labels: labels, color: color),
            const SizedBox(height: 8),
            Text(
              report.tip,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
