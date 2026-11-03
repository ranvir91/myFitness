import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../hydration/hydration_provider.dart';
import '../posture/posture_provider.dart';
import '../workout/workout_provider.dart';
import 'badge_engine.dart';
import 'widgets/badge_tile.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hydration = context.watch<HydrationProvider>();
    final workout = context.watch<WorkoutProvider>();
    final posture = context.watch<PostureProvider>();

    final ready = hydration.loaded && workout.loaded && posture.loaded;

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : _BadgesBody(hydration: hydration, workout: workout, posture: posture),
    );
  }
}

class _BadgesBody extends StatelessWidget {
  const _BadgesBody({
    required this.hydration,
    required this.workout,
    required this.posture,
  });

  final HydrationProvider hydration;
  final WorkoutProvider workout;
  final PostureProvider posture;

  @override
  Widget build(BuildContext context) {
    final badges = BadgeEngine.build(
      hydrationEntries: hydration.entries,
      hydrationGoalMl: hydration.goalMl,
      workoutSets: workout.history,
      workoutGoalReps: workout.dailyGoalReps,
      routines: workout.routines,
      postureChecks: posture.history,
    );
    final unlockedCount = badges.where((b) => b.unlocked).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$unlockedCount of ${badges.length} unlocked',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badges.isEmpty ? 0 : unlockedCount / badges.length,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) => BadgeTile(badge: badges[index]),
          ),
        ),
      ],
    );
  }
}
