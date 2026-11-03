import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_action_handler.dart';

/// Which set of quick-log action buttons (if any) a notification should
/// carry. Drives both the Android [AndroidNotificationAction]s and the iOS
/// [DarwinNotificationCategory] identifier.
enum NotificationCategory { none, hydration, posture }

const _hydrationCategoryId = 'hydrationCategory';
const _postureCategoryId = 'postureCategory';

/// Invoked on a background isolate when the user taps a notification action
/// while the app is terminated. Must be a top-level/static function.
@pragma('vm:entry-point')
void notificationBackgroundResponseHandler(NotificationResponse response) {
  NotificationActionHandler.handle(response.actionId);
}

/// Thin wrapper around flutter_local_notifications so features can
/// schedule/cancel reminders without touching plugin details directly.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Bumped whenever a notification action writes data directly to storage
  /// (bypassing the live Provider instances) while the app is in the
  /// foreground — providers listen to this to refresh from storage.
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Fall back to UTC if the device timezone name can't be resolved;
      // reminders still fire, just anchored to UTC offsets.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    final iosInit = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _hydrationCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              NotificationActionIds.hydrate250,
              '+250ml',
            ),
            DarwinNotificationAction.plain(
              NotificationActionIds.hydrate500,
              '+500ml',
            ),
          ],
        ),
        DarwinNotificationCategory(
          _postureCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              NotificationActionIds.postureGood,
              'Good',
            ),
            DarwinNotificationAction.plain(
              NotificationActionIds.postureAdjusted,
              'Adjusted',
            ),
          ],
        ),
      ],
    );
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      linux: linuxInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundResponseHandler,
    );
    _initialized = true;
  }

  void _onForegroundResponse(NotificationResponse response) {
    NotificationActionHandler.handle(response.actionId).then((handled) {
      if (handled) dataVersion.value++;
    });
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await init();
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final androidGranted =
          await androidImpl?.requestNotificationsPermission();
      final iosGranted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return (androidGranted ?? true) && (iosGranted ?? true);
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String channelId = 'general',
    String channelName = 'General',
  }) async {
    if (!_initialized) await init();
    await _plugin.show(id, title, body, _details(channelId, channelName));
  }

  /// Schedules a recurring reminder every [intervalMinutes] minutes. The
  /// first notification fires [intervalMinutes] from now, then repeats on
  /// that cadence indefinitely until cancelled. If [category] isn't
  /// [NotificationCategory.none], the notification carries quick-log action
  /// buttons that log data directly without opening the app.
  Future<void> scheduleRecurring({
    required int id,
    required String title,
    required String body,
    required int intervalMinutes,
    String channelId = 'general',
    String channelName = 'General',
    NotificationCategory category = NotificationCategory.none,
  }) async {
    if (!_initialized) await init();
    await cancel(id);

    await _plugin.periodicallyShowWithDuration(
      id,
      title,
      body,
      Duration(minutes: intervalMinutes),
      _details(channelId, channelName, category: category),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'interval:$intervalMinutes',
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String channelId = 'general',
    String channelName = 'General',
  }) async {
    if (!_initialized) await init();
    await cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(channelId, channelName),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async {
    if (!_initialized) await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_initialized) await init();
    await _plugin.cancelAll();
  }

  NotificationDetails _details(
    String channelId,
    String channelName, {
    NotificationCategory category = NotificationCategory.none,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        actions: _androidActionsFor(category),
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _darwinCategoryIdFor(category),
      ),
      linux: const LinuxNotificationDetails(),
    );
  }

  List<AndroidNotificationAction> _androidActionsFor(
    NotificationCategory category,
  ) {
    switch (category) {
      case NotificationCategory.hydration:
        return const [
          AndroidNotificationAction(
            NotificationActionIds.hydrate250,
            '+250ml',
          ),
          AndroidNotificationAction(
            NotificationActionIds.hydrate500,
            '+500ml',
          ),
        ];
      case NotificationCategory.posture:
        return const [
          AndroidNotificationAction(
            NotificationActionIds.postureGood,
            'Good',
          ),
          AndroidNotificationAction(
            NotificationActionIds.postureAdjusted,
            'Adjusted',
          ),
        ];
      case NotificationCategory.none:
        return const [];
    }
  }

  String? _darwinCategoryIdFor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.hydration:
        return _hydrationCategoryId;
      case NotificationCategory.posture:
        return _postureCategoryId;
      case NotificationCategory.none:
        return null;
    }
  }
}
