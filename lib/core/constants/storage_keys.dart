/// Storage keys shared between feature providers and
/// [NotificationActionHandler], which writes directly to storage from a
/// background isolate (so it can't go through the live Provider instances).
class StorageKeys {
  StorageKeys._();

  static const hydrationEntries = 'hydration_entries';
  static const postureHistory = 'posture_history';
}
