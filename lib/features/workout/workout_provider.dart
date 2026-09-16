import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/workout_set.dart';
import '../../core/services/storage_service.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._storage) {
    _load();
  }

  static const _historyKey = 'workout_history';
  static const _exerciseKey = 'workout_current_exercise';
  static const _dailyGoalKey = 'workout_daily_goal_reps';
  static const _uuid = Uuid();

  static const defaultExercises = [
    'Push-ups',
    'Squats',
    'Sit-ups',
    'Bicep Curls',
    'Lunges',
    'Pull-ups',
    'Jumping Jacks',
  ];

  final StorageService _storage;

  List<WorkoutSet> _history = [];
  String _currentExercise = defaultExercises.first;
  int _currentReps = 0;
  int _dailyGoalReps = 60;
  bool _loaded = false;

  List<WorkoutSet> get history => List.unmodifiable(_history);
  String get currentExercise => _currentExercise;
  int get currentReps => _currentReps;
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

  Future<void> _load() async {
    final storedHistory = _storage.getJson<List<WorkoutSet>>(
      _historyKey,
      (decoded) => (decoded as List)
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (storedHistory != null) _history = storedHistory;
    _currentExercise = _storage.getString(_exerciseKey) ?? defaultExercises.first;
    _dailyGoalReps = _storage.getInt(_dailyGoalKey) ?? 60;

    _loaded = true;
    notifyListeners();
  }

  void increment() {
    _currentReps++;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void decrement() {
    if (_currentReps > 0) {
      _currentReps--;
      notifyListeners();
    }
  }

  void resetCounter() {
    _currentReps = 0;
    notifyListeners();
  }

  Future<void> setExercise(String exercise) async {
    _currentExercise = exercise;
    await _storage.setString(_exerciseKey, exercise);
    notifyListeners();
  }

  Future<void> setDailyGoalReps(int reps) async {
    _dailyGoalReps = reps;
    await _storage.setInt(_dailyGoalKey, reps);
    notifyListeners();
  }

  /// Saves the current rep count as a completed set and resets the counter.
  Future<void> completeSet() async {
    if (_currentReps == 0) return;
    final set = WorkoutSet(
      id: _uuid.v4(),
      exercise: _currentExercise,
      reps: _currentReps,
      timestamp: DateTime.now(),
    );
    _history.add(set);
    _currentReps = 0;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteSet(String id) async {
    _history.removeWhere((s) => s.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.setJson(
      _historyKey,
      _history.map((e) => e.toJson()).toList(),
    );
  }
}
