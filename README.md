# Fit Myself

A Flutter fitness companion app with six feature areas:

- **Hydration & Drink Reminder** — log water intake against a daily goal, quick-add common amounts, track a daily streak, and get periodic reminder notifications with quick-log action buttons ("+250ml" / "+500ml") that log without opening the app.
- **Workout Rep Counter** — a user-managed list of exercises (seeded from suggestions, fully customizable) shown as a daily done/missed checklist. Checking an exercise logs reps for it via a date + rep-preset picker; tapping an exercise opens its full history, where entries can be added for any past date too. Rep presets and the daily rep goal are configurable in Workout settings. **Routines** group several exercises into a reusable set that can be logged all at once.
- **Posture Check Reminder** — periodic nudges to check your posture, with a one-tap "good / adjusted" log (also available as notification action buttons) and daily stats.
- **Reports** — a week/month view across all three modules: a daily (or weekly, for month view) score against each module's goal, an overall verdict (Great / Good / Needs work / No data), and a "where to improve" callout naming the weakest area with a concrete tip.
- **Badges** — unlocked purely from existing history (streaks, totals, "perfect days" where all three goals were hit) — no separate unlock-state storage, so badges can never drift out of sync with the data that earned them.
- **Profile & weight tracking** — age/height/goal weight, a weight log with one entry per day, a trend chart against the goal line, BMI, and progress-toward-goal tracking for a weight-loss (or gain) journey.

## Architecture

- State management: `provider` (one `ChangeNotifier` per module).
- Persistence: `shared_preferences`, wrapped by `StorageService` for JSON (de)serialization.
- Reminders: `flutter_local_notifications` via `NotificationService`, scheduling truly recurring (`periodicallyShowWithDuration`) notifications per module. Scheduled/recurring notifications require the receivers declared in `android/app/src/main/AndroidManifest.xml` (`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`, `ActionBroadcastReceiver`) — flutter_local_notifications does not merge these in automatically.

```
lib/
  core/
    constants/     # kExerciseSuggestions, StorageKeys shared between providers and the notification action handler
    models/        # Plain data classes (HydrationEntry, WorkoutSet, WorkoutRoutine, PostureCheck, WeightEntry)
    services/      # NotificationService, NotificationActionHandler, StorageService
    theme/         # App-wide Material 3 theme
  features/
    home/          # Dashboard + bottom navigation shell
    hydration/
    workout/       # Checklist, routines, exercise detail, settings (exercises + rep presets)
    posture/
    profile/       # Age/height/goal weight + weight trend chart
    badges/        # BadgeEngine (pure calculation) + badge grid UI
    reports/       # ReportEngine (pure calculation) + report UI
  app.dart
  main.dart
```

### Reports scoring

Each module's daily score is `min(100, actual / goal * 100)`:
hydration ml vs. daily goal, workout reps vs. daily goal, and posture
`good checks / total checks` for days with at least one check logged.
A module's overall verdict is based on its average score across the range:
`>=80% Great`, `50-79% Good`, `<50% Needs work`, or `No data` if nothing
was logged. The "where to improve" callout points at whichever module has
the lowest average score.

### Badges

`BadgeEngine.build()` computes unlock status live from each module's full
history — e.g. a streak badge scans for the *longest-ever* consecutive run
of qualifying days, not just the currently active streak, which makes
"unlocked" permanent without needing separate persisted unlock-state (once
a streak of N happened, that fact is permanently in the data).

### Actionable notifications

Hydration and posture reminders carry quick-log action buttons. Because an
action can be tapped while the app is fully terminated, the write path
(`NotificationActionHandler`) does **not** go through the live `Provider`
instances — it writes straight to `SharedPreferences` using the same keys
(`StorageKeys`) the providers read on launch. When the app *is* open,
`NotificationService.dataVersion` (a `ValueNotifier<int>`) is bumped after a
foreground action so `HydrationProvider`/`PostureProvider` can reload and
reflect it immediately without a restart.

This could only be verified by build + static analysis in this environment
(no physical device/emulator with notification tray interaction available) —
test actual action-button delivery on a real device before relying on it.

### Branding / app icon

Source branding images live in `assets/icon/app_icon.png` (1024x1024, used to
generate all platform launcher icons) and `assets/branding/` (in-app logo
images). Icons are generated via `flutter_launcher_icons`:

```bash
dart run flutter_launcher_icons
```

Re-run this after replacing `assets/icon/app_icon.png` with a new source image.

## Getting started

```bash
flutter pub get
flutter run            # or: flutter run -d linux / -d chrome
flutter test
flutter analyze
```

### Notifications

On Android 13+ and iOS, notification permission is requested automatically
on first app launch (see `main.dart`) so reminders can be scheduled. Each
reminder's settings sheet (Hydration, Posture) has a "Send test
notification" button to verify delivery immediately without waiting for the
configured interval (test notifications don't carry action buttons, since
they're meant purely to confirm delivery works).
