import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/exercise_suggestions.dart';
import '../../core/models/workout_routine.dart';
import '../../core/models/workout_set.dart';
import '../../core/services/storage_service.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._storage) {
    _load();
  }

  static const _historyKey = 'workout_history';
  static const _exercisesKey = 'workout_custom_exercises';
  static const _repPresetsKey = 'workout_rep_presets';
  static const _dailyGoalKey = 'workout_daily_goal_reps';
  static const _routinesKey = 'workout_routines';
  static const _uuid = Uuid();

  static const defaultExercises = kExerciseSuggestions;
  static const _defaultSeedExercises = ['Push-ups', 'Squats', 'Sit-ups'];
  static const _defaultRepPresets = [10, 20, 30, 50];

  final StorageService _storage;

  List<WorkoutSet> _history = [];
  List<String> _customExercises = [];
  List<int> _repPresets = [];
  List<WorkoutRoutine> _routines = [];
  int _dailyGoalReps = 60;
  bool _loaded = false;

  List<WorkoutSet> get history => List.unmodifiable(_history);
  List<String> get customExercises => List.unmodifiable(_customExercises);
  List<int> get repPresets => List.unmodifiable(_repPresets);
  List<WorkoutRoutine> get routines => List.unmodifiable(_routines);
  int get dailyGoalReps => _dailyGoalReps;
  bool get loaded => _loaded;

  List<WorkoutSet> get todaySets {
    final now = DateTime.now();
    return _history
        .where((s) =>
            s.timestamp.year == now.year &&
            s.timestamp.month == now.month &&
            s.timestamp.day == now.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int get todayTotalReps => todaySets.fold(0, (sum, s) => sum + s.reps);

  int get todayDoneCount =>
      _customExercises.where(isDoneToday).length;

  List<WorkoutSet> entriesFor(String exercise) {
    return _history.where((s) => s.exercise == exercise).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<WorkoutSet> _entriesForOnDate(String exercise, DateTime date) {
    return _history
        .where((s) =>
            s.exercise == exercise &&
            s.timestamp.year == date.year &&
            s.timestamp.month == date.month &&
            s.timestamp.day == date.day)
        .toList();
  }

  bool isDoneToday(String exercise) =>
      _entriesForOnDate(exercise, DateTime.now()).isNotEmpty;

  int todayRepsFor(String exercise) => _entriesForOnDate(exercise, DateTime.now())
      .fold(0, (sum, s) => sum + s.reps);

  Future<void> _load() async {
    final storedHistory = _storage.getJson<List<WorkoutSet>>(
      _historyKey,
      (decoded) => (decoded as List)
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (storedHistory != null) _history = storedHistory;

    final storedExercises = _storage.getJson<List<String>>(
      _exercisesKey,
      (decoded) => (decoded as List).cast<String>(),
    );
    _customExercises = storedExercises ?? List.of(_defaultSeedExercises);

    final storedPresets = _storage.getJson<List<int>>(
      _repPresetsKey,
      (decoded) => (decoded as List).map((e) => e as int).toList(),
    );
    _repPresets = storedPresets ?? List.of(_defaultRepPresets);

    _dailyGoalReps = _storage.getInt(_dailyGoalKey) ?? 60;

    final storedRoutines = _storage.getJson<List<WorkoutRoutine>>(
      _routinesKey,
      (decoded) => (decoded as List)
          .map((e) => WorkoutRoutine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (storedRoutines != null) _routines = storedRoutines;

    _loaded = true;
    notifyListeners();
  }

  Future<void> setDailyGoalReps(int reps) async {
    _dailyGoalReps = reps;
    await _storage.setInt(_dailyGoalKey, reps);
    notifyListeners();
  }

  Future<void> addExercise(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _customExercises.contains(trimmed)) return;
    _customExercises.add(trimmed);
    await _persistExercises();
    notifyListeners();
  }

  /// Removes an exercise from the active list, deletes its logged history,
  /// and strips it out of any routines that reference it.
  Future<void> removeExercise(String name) async {
    _customExercises.remove(name);
    _history.removeWhere((s) => s.exercise == name);
    _routines = _routines
        .map((r) => WorkoutRoutine(
              id: r.id,
              name: r.name,
              exercises: r.exercises.where((e) => e != name).toList(),
            ))
        .where((r) => r.exercises.isNotEmpty)
        .toList();
    await _persistExercises();
    await _persistHistory();
    await _persistRoutines();
    notifyListeners();
  }

  Future<void> addRepPreset(int value) async {
    if (value <= 0 || _repPresets.contains(value)) return;
    _repPresets.add(value);
    _repPresets.sort();
    await _persistRepPresets();
    notifyListeners();
  }

  Future<void> removeRepPreset(int value) async {
    _repPresets.remove(value);
    await _persistRepPresets();
    notifyListeners();
  }

  /// Logs a rep entry for [exercise] on [date] (defaults to the current
  /// moment, so same-day entries sort naturally alongside each other).
  Future<void> logEntry({
    required String exercise,
    required int reps,
    DateTime? date,
  }) async {
    final set = WorkoutSet(
      id: _uuid.v4(),
      exercise: exercise,
      reps: reps,
      timestamp: date ?? DateTime.now(),
    );
    _history.add(set);
    await _persistHistory();
    notifyListeners();
  }

  /// Removes all of today's logged entries for [exercise] — used to
  /// "un-tick" an exercise on the daily checklist.
  Future<void> clearTodayEntries(String exercise) async {
    _history.removeWhere((s) =>
        s.exercise == exercise &&
        _isSameDay(s.timestamp, DateTime.now()));
    await _persistHistory();
    notifyListeners();
  }

  Future<void> deleteSet(String id) async {
    _history.removeWhere((s) => s.id == id);
    await _persistHistory();
    notifyListeners();
  }

  Future<void> addRoutine(String name, List<String> exercises) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || exercises.isEmpty) return;
    _routines.add(WorkoutRoutine(id: _uuid.v4(), name: trimmed, exercises: exercises));
    await _persistRoutines();
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    _routines.removeWhere((r) => r.id == id);
    await _persistRoutines();
    notifyListeners();
  }

  /// Logs one entry per exercise in [reps] (exercise -> reps) for [date]
  /// (defaults to now) in a single batch — used to log an entire routine
  /// at once instead of one exercise at a time.
  Future<void> logRoutine(Map<String, int> reps, {DateTime? date}) async {
    final when = date ?? DateTime.now();
    for (final entry in reps.entries) {
      if (entry.value <= 0) continue;
      _history.add(WorkoutSet(
        id: _uuid.v4(),
        exercise: entry.key,
        reps: entry.value,
        timestamp: when,
      ));
    }
    await _persistHistory();
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _persistHistory() async {
    await _storage.setJson(
      _historyKey,
      _history.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _persistExercises() async {
    await _storage.setJson(_exercisesKey, _customExercises);
  }

  Future<void> _persistRepPresets() async {
    await _storage.setJson(_repPresetsKey, _repPresets);
  }

  Future<void> _persistRoutines() async {
    await _storage.setJson(
      _routinesKey,
      _routines.map((r) => r.toJson()).toList(),
    );
  }
}
