import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/models/hydration_entry.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';

class HydrationProvider extends ChangeNotifier {
  HydrationProvider(this._storage) {
    _load();
    NotificationService.instance.dataVersion.addListener(_onExternalDataChanged);
  }

  static const _entriesKey = StorageKeys.hydrationEntries;
  static const _goalKey = 'hydration_goal_ml';
  static const _reminderEnabledKey = 'hydration_reminder_enabled';
  static const _reminderIntervalKey = 'hydration_reminder_interval_min';
  static const notificationId = 1001;
  static const _uuid = Uuid();

  final StorageService _storage;

  List<HydrationEntry> _entries = [];
  int _goalMl = 2000;
  bool _reminderEnabled = false;
  int _reminderIntervalMinutes = 60;
  bool _loaded = false;

  List<HydrationEntry> get entries => List.unmodifiable(_entries);
  int get goalMl => _goalMl;
  bool get reminderEnabled => _reminderEnabled;
  int get reminderIntervalMinutes => _reminderIntervalMinutes;
  bool get loaded => _loaded;

  List<HydrationEntry> get todayEntries {
    final now = DateTime.now();
    return _entries
        .where((e) =>
            e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day == now.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int get todayTotalMl =>
      todayEntries.fold(0, (sum, e) => sum + e.amountMl);

  double get progress => (_goalMl == 0) ? 0 : (todayTotalMl / _goalMl).clamp(0, 1);

  /// Number of consecutive days (ending today or yesterday) the goal was met.
  int get streakDays {
    final byDay = <DateTime, int>{};
    for (final e in _entries) {
      final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      byDay[day] = (byDay[day] ?? 0) + e.amountMl;
    }
    var streak = 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    while (true) {
      final total = byDay[day] ?? 0;
      if (total >= _goalMl) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  List<HydrationEntry>? _readEntriesFromStorage() {
    return _storage.getJson<List<HydrationEntry>>(
      _entriesKey,
      (decoded) => (decoded as List)
          .map((e) => HydrationEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Re-reads entries written by [NotificationActionHandler] from a quick-log
  /// notification action, so the UI reflects them without a restart.
  void _onExternalDataChanged() {
    final storedEntries = _readEntriesFromStorage();
    if (storedEntries != null) {
      _entries = storedEntries;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    NotificationService.instance.dataVersion.removeListener(_onExternalDataChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final storedEntries = _readEntriesFromStorage();
    if (storedEntries != null) _entries = storedEntries;

    _goalMl = _storage.getInt(_goalKey) ?? 2000;
    _reminderEnabled = _storage.getBool(_reminderEnabledKey) ?? false;
    _reminderIntervalMinutes = _storage.getInt(_reminderIntervalKey) ?? 60;

    _loaded = true;
    notifyListeners();

    if (_reminderEnabled) {
      await _scheduleReminder();
    }
  }

  Future<void> addDrink(int amountMl) async {
    final entry = HydrationEntry(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: DateTime.now(),
    );
    _entries.add(entry);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> setGoal(int goalMl) async {
    _goalMl = goalMl;
    await _storage.setInt(_goalKey, goalMl);
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    await _storage.setBool(_reminderEnabledKey, enabled);
    if (enabled) {
      await _scheduleReminder();
    } else {
      await NotificationService.instance.cancel(notificationId);
    }
    notifyListeners();
  }

  Future<void> setReminderInterval(int minutes) async {
    _reminderIntervalMinutes = minutes;
    await _storage.setInt(_reminderIntervalKey, minutes);
    if (_reminderEnabled) {
      await _scheduleReminder();
    }
    notifyListeners();
  }

  Future<void> _scheduleReminder() async {
    await NotificationService.instance.scheduleRecurring(
      id: notificationId,
      title: 'Time to hydrate 💧',
      body: 'Take a moment to drink some water.',
      intervalMinutes: _reminderIntervalMinutes,
      channelId: 'hydration',
      channelName: 'Hydration Reminders',
      category: NotificationCategory.hydration,
    );
  }

  Future<void> _persistEntries() async {
    await _storage.setJson(
      _entriesKey,
      _entries.map((e) => e.toJson()).toList(),
    );
  }
}
