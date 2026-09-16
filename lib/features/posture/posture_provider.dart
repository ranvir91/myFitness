import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/posture_check.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';

class PostureProvider extends ChangeNotifier {
  PostureProvider(this._storage) {
    _load();
  }

  static const _historyKey = 'posture_history';
  static const _reminderEnabledKey = 'posture_reminder_enabled';
  static const _reminderIntervalKey = 'posture_reminder_interval_min';
  static const notificationId = 2001;
  static const _uuid = Uuid();

  final StorageService _storage;

  List<PostureCheck> _history = [];
  bool _reminderEnabled = false;
  int _reminderIntervalMinutes = 45;
  bool _loaded = false;

  List<PostureCheck> get history => List.unmodifiable(_history);
  bool get reminderEnabled => _reminderEnabled;
  int get reminderIntervalMinutes => _reminderIntervalMinutes;
  bool get loaded => _loaded;

  List<PostureCheck> get todayChecks {
    final now = DateTime.now();
    return _history
        .where((c) =>
            c.timestamp.year == now.year &&
            c.timestamp.month == now.month &&
            c.timestamp.day == now.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int get todayGoodCount =>
      todayChecks.where((c) => c.status == PostureStatus.good).length;

  int get todayAdjustedCount =>
      todayChecks.where((c) => c.status == PostureStatus.adjusted).length;

  DateTime? get lastCheckTime =>
      _history.isEmpty ? null : _history.last.timestamp;

  Future<void> _load() async {
    final storedHistory = _storage.getJson<List<PostureCheck>>(
      _historyKey,
      (decoded) => (decoded as List)
          .map((e) => PostureCheck.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (storedHistory != null) _history = storedHistory;

    _reminderEnabled = _storage.getBool(_reminderEnabledKey) ?? false;
    _reminderIntervalMinutes = _storage.getInt(_reminderIntervalKey) ?? 45;

    _loaded = true;
    notifyListeners();

    if (_reminderEnabled) {
      await _scheduleReminder();
    }
  }

  Future<void> logCheck(PostureStatus status) async {
    final check = PostureCheck(
      id: _uuid.v4(),
      status: status,
      timestamp: DateTime.now(),
    );
    _history.add(check);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteCheck(String id) async {
    _history.removeWhere((c) => c.id == id);
    await _persist();
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
      title: 'Posture check 🧍',
      body: 'Sit up straight — how does your posture look right now?',
      intervalMinutes: _reminderIntervalMinutes,
      channelId: 'posture',
      channelName: 'Posture Reminders',
    );
  }

  Future<void> _persist() async {
    await _storage.setJson(
      _historyKey,
      _history.map((e) => e.toJson()).toList(),
    );
  }
}
