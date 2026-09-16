import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../hydration/hydration_provider.dart';
import '../posture/posture_provider.dart';
import '../workout/workout_provider.dart';
import 'report_engine.dart';
import 'widgets/module_report_card.dart';
import 'widgets/verdict_badge.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportRange _range = ReportRange.week;

  @override
  Widget build(BuildContext context) {
    final hydration = context.watch<HydrationProvider>();
    final workout = context.watch<WorkoutProvider>();
    final posture = context.watch<PostureProvider>();

    final ready = hydration.loaded && workout.loaded && posture.loaded;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : _ReportBody(
              range: _range,
              onRangeChanged: (r) => setState(() => _range = r),
              hydration: hydration,
              workout: workout,
              posture: posture,
            ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.range,
    required this.onRangeChanged,
    required this.hydration,
    required this.workout,
    required this.posture,
  });

  final ReportRange range;
  final ValueChanged<ReportRange> onRangeChanged;
  final HydrationProvider hydration;
  final WorkoutProvider workout;
  final PostureProvider posture;

  @override
  Widget build(BuildContext context) {
    final report = ReportEngine.build(
      range: range,
      hydrationEntries: hydration.entries,
      hydrationGoalMl: hydration.goalMl,
      workoutSets: workout.history,
      workoutGoalReps: workout.dailyGoalReps,
      postureChecks: posture.history,
    );

    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: SegmentedButton<ReportRange>(
            segments: const [
              ButtonSegment(value: ReportRange.week, label: Text('Last week')),
              ButtonSegment(value: ReportRange.month, label: Text('Last month')),
            ],
            selected: {range},
            onSelectionChanged: (s) => onRangeChanged(s.first),
          ),
        ),
        const SizedBox(height: 20),
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
                      child: Text(
                        report.headline,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    VerdictBadge(verdict: report.overallVerdict),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Overall score: ${report.overallScore.round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (report.focusArea != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Where to improve — ${report.focusArea}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ModuleReportCard(
          title: 'Hydration',
          icon: Icons.water_drop,
          color: Colors.blue,
          report: report.hydration,
          labels: report.labels,
          activityNoun: 'days logged',
        ),
        const SizedBox(height: 16),
        ModuleReportCard(
          title: 'Workout',
          icon: Icons.fitness_center,
          color: Colors.deepOrange,
          report: report.workout,
          labels: report.labels,
          activityNoun: 'active days',
        ),
        const SizedBox(height: 16),
        ModuleReportCard(
          title: 'Posture',
          icon: Icons.accessibility_new,
          color: Colors.teal,
          report: report.posture,
          labels: report.labels,
          activityNoun: 'days checked',
        ),
      ],
    );
  }
}
