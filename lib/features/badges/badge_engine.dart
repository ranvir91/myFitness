import 'package:flutter/material.dart';

import '../../core/models/hydration_entry.dart';
import '../../core/models/posture_check.dart';
import '../../core/models/workout_routine.dart';
import '../../core/models/workout_set.dart';

enum BadgeModule { hydration, workout, posture, overall }

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.module,
    required this.unlocked,
    this.progress,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final BadgeModule module;
  final bool unlocked;

  /// Optional "3 / 7" style progress label shown on locked badges.
  final String? progress;
}

class BadgeEngine {
  BadgeEngine._();

  static List<BadgeDefinition> build({
    required List<HydrationEntry> hydrationEntries,
    required int hydrationGoalMl,
    required List<WorkoutSet> workoutSets,
    required int workoutGoalReps,
    required List<WorkoutRoutine> routines,
    required List<PostureCheck> postureChecks,
  }) {
    final hydrationByDay = <DateTime, int>{};
    for (final e in hydrationEntries) {
      final day = _dateOnly(e.timestamp);
      hydrationByDay[day] = (hydrationByDay[day] ?? 0) + e.amountMl;
    }
    final hydrationQualifyingDays = hydrationGoalMl == 0
        ? <DateTime>{}
        : hydrationByDay.entries
            .where((e) => e.value >= hydrationGoalMl)
            .map((e) => e.key)
            .toSet();
    final hydrationStreak = _longestStreak(hydrationQualifyingDays);

    final workoutByDay = <DateTime, int>{};
    for (final s in workoutSets) {
      final day = _dateOnly(s.timestamp);
      workoutByDay[day] = (workoutByDay[day] ?? 0) + s.reps;
    }
    final workoutQualifyingDays = workoutGoalReps == 0
        ? <DateTime>{}
        : workoutByDay.entries
            .where((e) => e.value >= workoutGoalReps)
            .map((e) => e.key)
            .toSet();
    final maxRepsInADay =
        workoutByDay.values.fold<int>(0, (max, v) => v > max ? v : max);

    final postureGoodByDay = <DateTime, int>{};
    var totalGoodChecks = 0;
    for (final c in postureChecks) {
      if (c.status != PostureStatus.good) continue;
      totalGoodChecks++;
      final day = _dateOnly(c.timestamp);
      postureGoodByDay[day] = (postureGoodByDay[day] ?? 0) + 1;
    }
    final postureQualifyingDays = postureGoodByDay.keys.toSet();
    final postureStreak = _longestStreak(postureQualifyingDays);

    final perfectDays = hydrationQualifyingDays
        .intersection(workoutQualifyingDays)
        .intersection(postureQualifyingDays)
        .length;

    return [
      // Hydration
      BadgeDefinition(
        id: 'hydration_first',
        title: 'First Sip',
        description: 'Log your first drink.',
        icon: Icons.water_drop,
        module: BadgeModule.hydration,
        unlocked: hydrationEntries.isNotEmpty,
      ),
      BadgeDefinition(
        id: 'hydration_streak_3',
        title: '3-Day Streak',
        description: 'Hit your hydration goal 3 days in a row.',
        icon: Icons.local_fire_department,
        module: BadgeModule.hydration,
        unlocked: hydrationStreak >= 3,
        progress: '${hydrationStreak.clamp(0, 3)} / 3 days',
      ),
      BadgeDefinition(
        id: 'hydration_streak_7',
        title: '7-Day Streak',
        description: 'Hit your hydration goal 7 days in a row.',
        icon: Icons.local_fire_department,
        module: BadgeModule.hydration,
        unlocked: hydrationStreak >= 7,
        progress: '${hydrationStreak.clamp(0, 7)} / 7 days',
      ),
      BadgeDefinition(
        id: 'hydration_streak_30',
        title: '30-Day Streak',
        description: 'Hit your hydration goal 30 days in a row.',
        icon: Icons.emoji_events,
        module: BadgeModule.hydration,
        unlocked: hydrationStreak >= 30,
        progress: '${hydrationStreak.clamp(0, 30)} / 30 days',
      ),
      // Workout
      BadgeDefinition(
        id: 'workout_first',
        title: 'First Rep',
        description: 'Log your first workout set.',
        icon: Icons.fitness_center,
        module: BadgeModule.workout,
        unlocked: workoutSets.isNotEmpty,
      ),
      BadgeDefinition(
        id: 'workout_10',
        title: '10 Workouts Logged',
        description: 'Log 10 workout sets in total.',
        icon: Icons.fitness_center,
        module: BadgeModule.workout,
        unlocked: workoutSets.length >= 10,
        progress: '${workoutSets.length.clamp(0, 10)} / 10 sets',
      ),
      BadgeDefinition(
        id: 'workout_50',
        title: '50 Workouts Logged',
        description: 'Log 50 workout sets in total.',
        icon: Icons.military_tech,
        module: BadgeModule.workout,
        unlocked: workoutSets.length >= 50,
        progress: '${workoutSets.length.clamp(0, 50)} / 50 sets',
      ),
      BadgeDefinition(
        id: 'workout_routine_builder',
        title: 'Routine Builder',
        description: 'Create your first workout routine.',
        icon: Icons.list_alt,
        module: BadgeModule.workout,
        unlocked: routines.isNotEmpty,
      ),
      BadgeDefinition(
        id: 'workout_century',
        title: 'Century Day',
        description: 'Log 100+ reps in a single day.',
        icon: Icons.bolt,
        module: BadgeModule.workout,
        unlocked: maxRepsInADay >= 100,
        progress: '${maxRepsInADay.clamp(0, 100)} / 100 reps',
      ),
      // Posture
      BadgeDefinition(
        id: 'posture_first',
        title: 'First Check-In',
        description: 'Log your first posture check.',
        icon: Icons.accessibility_new,
        module: BadgeModule.posture,
        unlocked: postureChecks.isNotEmpty,
      ),
      BadgeDefinition(
        id: 'posture_streak_7',
        title: '7-Day Streak',
        description: 'Log a "good" posture check 7 days in a row.',
        icon: Icons.local_fire_department,
        module: BadgeModule.posture,
        unlocked: postureStreak >= 7,
        progress: '${postureStreak.clamp(0, 7)} / 7 days',
      ),
      BadgeDefinition(
        id: 'posture_100_good',
        title: '100 Good Checks',
        description: 'Log 100 "good" posture checks in total.',
        icon: Icons.emoji_events,
        module: BadgeModule.posture,
        unlocked: totalGoodChecks >= 100,
        progress: '${totalGoodChecks.clamp(0, 100)} / 100 checks',
      ),
      // Cross-module
      BadgeDefinition(
        id: 'overall_perfect_day',
        title: 'Perfect Day',
        description: 'Hit your hydration, workout, and posture goals all on the same day.',
        icon: Icons.star,
        module: BadgeModule.overall,
        unlocked: perfectDays >= 1,
      ),
      BadgeDefinition(
        id: 'overall_perfect_7',
        title: '7 Perfect Days',
        description: 'Hit all three goals on the same day, 7 different days total.',
        icon: Icons.workspace_premium,
        module: BadgeModule.overall,
        unlocked: perfectDays >= 7,
        progress: '${perfectDays.clamp(0, 7)} / 7 days',
      ),
    ];
  }

  /// Longest run of consecutive calendar days present in [days].
  static int _longestStreak(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final sorted = days.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
