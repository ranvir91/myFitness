import 'package:uuid/uuid.dart';

import '../constants/storage_keys.dart';
import '../models/hydration_entry.dart';
import '../models/posture_check.dart';
import 'storage_service.dart';

/// Action ids used by both the notification action buttons (Android/iOS)
/// and the handler below — must match exactly.
class NotificationActionIds {
  NotificationActionIds._();

  static const hydrate250 = 'hydrate_250';
  static const hydrate500 = 'hydrate_500';
  static const postureGood = 'posture_good';
  static const postureAdjusted = 'posture_adjusted';
}

/// Handles taps on notification action buttons. This must work even when
/// the app process is terminated (the plugin invokes it on a background
/// isolate in that case), so it writes directly to [StorageService] using
/// the same keys the live providers use, rather than going through a
/// Provider that may not exist in this isolate.
class NotificationActionHandler {
  NotificationActionHandler._();

  static const _uuid = Uuid();

  /// Returns true if [actionId] was recognized and handled.
  static Future<bool> handle(String? actionId) async {
    switch (actionId) {
      case NotificationActionIds.hydrate250:
        await _logHydration(250);
        return true;
      case NotificationActionIds.hydrate500:
        await _logHydration(500);
        return true;
      case NotificationActionIds.postureGood:
        await _logPosture(PostureStatus.good);
        return true;
      case NotificationActionIds.postureAdjusted:
        await _logPosture(PostureStatus.adjusted);
        return true;
      default:
        return false;
    }
  }

  static Future<void> _logHydration(int amountMl) async {
    final storage = await StorageService.getInstance();
    final entries = storage.getJson<List<HydrationEntry>>(
          StorageKeys.hydrationEntries,
          (decoded) => (decoded as List)
              .map((e) => HydrationEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ) ??
        [];
    entries.add(HydrationEntry(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: DateTime.now(),
    ));
    await storage.setJson(
      StorageKeys.hydrationEntries,
      entries.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> _logPosture(PostureStatus status) async {
    final storage = await StorageService.getInstance();
    final history = storage.getJson<List<PostureCheck>>(
          StorageKeys.postureHistory,
          (decoded) => (decoded as List)
              .map((e) => PostureCheck.fromJson(e as Map<String, dynamic>))
              .toList(),
        ) ??
        [];
    history.add(PostureCheck(
      id: _uuid.v4(),
      status: status,
      timestamp: DateTime.now(),
    ));
    await storage.setJson(
      StorageKeys.postureHistory,
      history.map((e) => e.toJson()).toList(),
    );
  }
}
