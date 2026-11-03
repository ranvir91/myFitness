import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/weight_entry.dart';
import '../../core/services/storage_service.dart';

enum BmiCategory { underweight, normal, overweight, obese }

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._storage) {
    _load();
  }

  static const _ageKey = 'profile_age';
  static const _heightKey = 'profile_height_cm';
  static const _goalWeightKey = 'profile_goal_weight_kg';
  static const _weightEntriesKey = 'profile_weight_entries';
  static const _uuid = Uuid();

  final StorageService _storage;

  int? _age;
  double? _heightCm;
  double? _goalWeightKg;
  List<WeightEntry> _weightEntries = [];
  bool _loaded = false;

  int? get age => _age;
  double? get heightCm => _heightCm;
  double? get goalWeightKg => _goalWeightKg;
  bool get loaded => _loaded;

  List<WeightEntry> get weightEntries {
    final sorted = List<WeightEntry>.of(_weightEntries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return List.unmodifiable(sorted);
  }

  WeightEntry? get latestEntry =>
      weightEntries.isEmpty ? null : weightEntries.last;

  WeightEntry? get firstEntry =>
      weightEntries.isEmpty ? null : weightEntries.first;

  double? get currentWeightKg => latestEntry?.weightKg;
  double? get startingWeightKg => firstEntry?.weightKg;

  double? get bmi {
    final weight = currentWeightKg;
    if (weight == null || _heightCm == null || _heightCm! <= 0) return null;
    final heightM = _heightCm! / 100;
    return weight / (heightM * heightM);
  }

  BmiCategory? get bmiCategory {
    final value = bmi;
    if (value == null) return null;
    if (value < 18.5) return BmiCategory.underweight;
    if (value < 25) return BmiCategory.normal;
    if (value < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Weight change since the first logged entry. Negative means lost weight.
  double? get changeSinceStart {
    final current = currentWeightKg;
    final start = startingWeightKg;
    if (current == null || start == null) return null;
    return current - start;
  }

  /// 0-1 progress toward [goalWeightKg] from the starting weight. Null if
  /// there isn't enough data (no goal, no entries, or start == goal).
  double? get progressToGoal {
    final current = currentWeightKg;
    final start = startingWeightKg;
    final goal = _goalWeightKg;
    if (current == null || start == null || goal == null) return null;
    final totalDelta = start - goal;
    if (totalDelta == 0) return 1;
    final doneSoFar = start - current;
    return (doneSoFar / totalDelta).clamp(0, 1);
  }

  double? get remainingToGoal {
    final current = currentWeightKg;
    if (current == null || _goalWeightKg == null) return null;
    return current - _goalWeightKg!;
  }

  Future<void> _load() async {
    _age = _storage.getInt(_ageKey);
    _heightCm = _storage.getDouble(_heightKey);
    _goalWeightKg = _storage.getDouble(_goalWeightKey);

    final storedEntries = _storage.getJson<List<WeightEntry>>(
      _weightEntriesKey,
      (decoded) => (decoded as List)
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (storedEntries != null) _weightEntries = storedEntries;

    _loaded = true;
    notifyListeners();
  }

  Future<void> setAge(int? age) async {
    _age = age;
    if (age == null) {
      await _storage.remove(_ageKey);
    } else {
      await _storage.setInt(_ageKey, age);
    }
    notifyListeners();
  }

  Future<void> setHeightCm(double? heightCm) async {
    _heightCm = heightCm;
    if (heightCm == null) {
      await _storage.remove(_heightKey);
    } else {
      await _storage.setDouble(_heightKey, heightCm);
    }
    notifyListeners();
  }

  Future<void> setGoalWeightKg(double? goalWeightKg) async {
    _goalWeightKg = goalWeightKg;
    if (goalWeightKg == null) {
      await _storage.remove(_goalWeightKey);
    } else {
      await _storage.setDouble(_goalWeightKey, goalWeightKg);
    }
    notifyListeners();
  }

  /// Logs (or replaces, if one already exists for that calendar day) a
  /// weight entry — weight is a once-a-day measurement, so keeping one
  /// point per day keeps the trend chart clean.
  Future<void> logWeight(double weightKg, {DateTime? date}) async {
    final when = date ?? DateTime.now();
    _weightEntries.removeWhere((e) => _isSameDay(e.timestamp, when));
    _weightEntries.add(WeightEntry(id: _uuid.v4(), weightKg: weightKg, timestamp: when));
    await _persist();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    _weightEntries.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _persist() async {
    await _storage.setJson(
      _weightEntriesKey,
      _weightEntries.map((e) => e.toJson()).toList(),
    );
  }
}
