import '../../core/models/hydration_entry.dart';
import '../../core/models/posture_check.dart';
import '../../core/models/workout_set.dart';

enum ReportRange { week, month }

enum ReportVerdict { great, good, needsImprovement, noData }

/// One bucket of aggregated activity — a single day (week view) or a
/// 7-day window (month view, so ~30 days render as a handful of bars).
class ReportBucket {
  const ReportBucket({
    required this.label,
    required this.hydrationScore,
    required this.workoutScore,
    required this.postureScore,
  });

  final String label;
  final double hydrationScore;
  final double workoutScore;
  final double postureScore;
}

class ModuleReport {
  const ModuleReport({
    required this.buckets,
    required this.averageScore,
    required this.activeUnits,
    required this.totalUnits,
    required this.verdict,
    required this.tip,
  });

  final List<double> buckets;
  final double averageScore;
  final int activeUnits;
  final int totalUnits;
  final ReportVerdict verdict;
  final String tip;
}

class WeeklyMonthlyReport {
  const WeeklyMonthlyReport({
    required this.range,
    required this.labels,
    required this.hydration,
    required this.workout,
    required this.posture,
    required this.overallScore,
    required this.overallVerdict,
    required this.headline,
    required this.focusArea,
  });

  final ReportRange range;
  final List<String> labels;
  final ModuleReport hydration;
  final ModuleReport workout;
  final ModuleReport posture;
  final double overallScore;
  final ReportVerdict overallVerdict;
  final String headline;
  final String? focusArea;
}

class ReportEngine {
  ReportEngine._();

  static WeeklyMonthlyReport build({
    required ReportRange range,
    required List<HydrationEntry> hydrationEntries,
    required int hydrationGoalMl,
    required List<WorkoutSet> workoutSets,
    required int workoutGoalReps,
    required List<PostureCheck> postureChecks,
  }) {
    final today = _dateOnly(DateTime.now());
    final days = range == ReportRange.week ? 7 : 28;
    final firstDay = today.subtract(Duration(days: days - 1));

    final hydrationByDay = <DateTime, int>{};
    for (final e in hydrationEntries) {
      final day = _dateOnly(e.timestamp);
      if (day.isBefore(firstDay)) continue;
      hydrationByDay[day] = (hydrationByDay[day] ?? 0) + e.amountMl;
    }

    final workoutByDay = <DateTime, int>{};
    for (final s in workoutSets) {
      final day = _dateOnly(s.timestamp);
      if (day.isBefore(firstDay)) continue;
      workoutByDay[day] = (workoutByDay[day] ?? 0) + s.reps;
    }

    final postureGoodByDay = <DateTime, int>{};
    final postureTotalByDay = <DateTime, int>{};
    for (final c in postureChecks) {
      final day = _dateOnly(c.timestamp);
      if (day.isBefore(firstDay)) continue;
      postureTotalByDay[day] = (postureTotalByDay[day] ?? 0) + 1;
      if (c.status == PostureStatus.good) {
        postureGoodByDay[day] = (postureGoodByDay[day] ?? 0) + 1;
      }
    }

    final dailyHydrationScores = <double>[];
    final dailyWorkoutScores = <double>[];
    final dailyPostureScores = <double>[];
    var hydrationActiveDays = 0;
    var workoutActiveDays = 0;
    var postureActiveDays = 0;

    for (var i = 0; i < days; i++) {
      final day = firstDay.add(Duration(days: i));

      final hydrationMl = hydrationByDay[day] ?? 0;
      if (hydrationMl > 0) hydrationActiveDays++;
      dailyHydrationScores.add(
        hydrationGoalMl == 0
            ? 0
            : (hydrationMl / hydrationGoalMl * 100).clamp(0, 100).toDouble(),
      );

      final reps = workoutByDay[day] ?? 0;
      if (reps > 0) workoutActiveDays++;
      dailyWorkoutScores.add(
        workoutGoalReps == 0
            ? 0
            : (reps / workoutGoalReps * 100).clamp(0, 100).toDouble(),
      );

      final total = postureTotalByDay[day] ?? 0;
      final good = postureGoodByDay[day] ?? 0;
      if (total > 0) postureActiveDays++;
      dailyPostureScores.add(total == 0 ? 0 : (good / total * 100));
    }

    final List<String> labels;
    final List<double> hydrationBuckets;
    final List<double> workoutBuckets;
    final List<double> postureBuckets;

    if (range == ReportRange.week) {
      labels = List.generate(days, (i) {
        final day = firstDay.add(Duration(days: i));
        return _weekdayLabel(day);
      });
      hydrationBuckets = dailyHydrationScores;
      workoutBuckets = dailyWorkoutScores;
      postureBuckets = dailyPostureScores;
    } else {
      final weeks = days ~/ 7;
      labels = List.generate(weeks, (w) {
        final start = firstDay.add(Duration(days: w * 7));
        return _shortDate(start);
      });
      hydrationBuckets = _weeklyAverages(dailyHydrationScores, weeks);
      workoutBuckets = _weeklyAverages(dailyWorkoutScores, weeks);
      postureBuckets = _weeklyAverages(dailyPostureScores, weeks);
    }

    final hydrationReport = _buildModuleReport(
      buckets: hydrationBuckets,
      activeUnits: hydrationActiveDays,
      totalUnits: days,
      moduleName: 'hydration',
      lowTip:
          'Your hydration intake is falling short of your goal. Try shortening your reminder interval, or enable reminders if they\'re off.',
      noDataTip:
          'No water intake logged in this period. Start logging drinks to build a hydration habit.',
    );
    final workoutReport = _buildModuleReport(
      buckets: workoutBuckets,
      activeUnits: workoutActiveDays,
      totalUnits: days,
      moduleName: 'workout',
      lowTip:
          'You\'re logging fewer reps than your daily goal. Consistency matters more than intensity — aim for at least one short set every day.',
      noDataTip:
          'No workouts logged in this period. Even a quick set of push-ups counts — try logging one today.',
    );
    final postureReport = _buildModuleReport(
      buckets: postureBuckets,
      activeUnits: postureActiveDays,
      totalUnits: days,
      moduleName: 'posture',
      lowTip:
          'Your posture checks skew toward "adjusted" rather than "good." Try a shorter reminder interval so you catch slouching sooner.',
      noDataTip:
          'No posture checks logged in this period. Turn on posture reminders to start tracking.',
    );

    final overallScore =
        (hydrationReport.averageScore + workoutReport.averageScore + postureReport.averageScore) / 3;
    final overallVerdict = _verdictFor(overallScore, wasEngaged: true);

    final rangeLabel = range == ReportRange.week ? 'week' : 'month';
    final headline = switch (overallVerdict) {
      ReportVerdict.great =>
        'You\'re doing great this $rangeLabel! Keep it up.',
      ReportVerdict.good =>
        'You\'re doing okay this $rangeLabel — a few areas need attention.',
      ReportVerdict.needsImprovement =>
        'This $rangeLabel needs some work — see below for where to focus.',
      ReportVerdict.noData => 'Not enough data logged yet this $rangeLabel.',
    };

    final modules = {
      'Hydration': hydrationReport,
      'Workout': workoutReport,
      'Posture': postureReport,
    };
    final lowestEntry = modules.entries
        .reduce((a, b) => a.value.averageScore <= b.value.averageScore ? a : b);
    final focusArea = lowestEntry.value.verdict == ReportVerdict.great
        ? null
        : '${lowestEntry.key}: ${lowestEntry.value.tip}';

    return WeeklyMonthlyReport(
      range: range,
      labels: labels,
      hydration: hydrationReport,
      workout: workoutReport,
      posture: postureReport,
      overallScore: overallScore,
      overallVerdict: overallVerdict,
      headline: headline,
      focusArea: focusArea,
    );
  }

  static ModuleReport _buildModuleReport({
    required List<double> buckets,
    required int activeUnits,
    required int totalUnits,
    required String moduleName,
    required String lowTip,
    required String noDataTip,
  }) {
    final average = buckets.isEmpty
        ? 0.0
        : buckets.reduce((a, b) => a + b) / buckets.length;
    final verdict = _verdictFor(average, wasEngaged: activeUnits > 0);
    final tip = switch (verdict) {
      ReportVerdict.noData => noDataTip,
      ReportVerdict.needsImprovement => lowTip,
      ReportVerdict.good => lowTip,
      ReportVerdict.great => 'Great consistency — keep this up.',
    };
    return ModuleReport(
      buckets: buckets,
      averageScore: average,
      activeUnits: activeUnits,
      totalUnits: totalUnits,
      verdict: verdict,
      tip: tip,
    );
  }

  static ReportVerdict _verdictFor(double score, {required bool wasEngaged}) {
    if (!wasEngaged) return ReportVerdict.noData;
    if (score >= 80) return ReportVerdict.great;
    if (score >= 50) return ReportVerdict.good;
    return ReportVerdict.needsImprovement;
  }

  static List<double> _weeklyAverages(List<double> daily, int weeks) {
    final result = <double>[];
    for (var w = 0; w < weeks; w++) {
      final slice = daily.skip(w * 7).take(7);
      final avg = slice.isEmpty
          ? 0.0
          : slice.reduce((a, b) => a + b) / slice.length;
      result.add(avg);
    }
    return result;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static const _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String _weekdayLabel(DateTime d) => _weekdayNames[d.weekday - 1];

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _shortDate(DateTime d) => '${_monthNames[d.month - 1]} ${d.day}';
}
