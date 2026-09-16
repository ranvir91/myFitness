# myFitness

A Flutter fitness companion app with four modules:

- **Hydration & Drink Reminder** — log water intake against a daily goal, quick-add common amounts, track a daily streak, and get periodic reminder notifications.
- **Workout Rep Counter** — a manual tap counter for logging sets per exercise (push-ups, squats, etc.), with a settable daily rep goal and a history of today's completed sets.
- **Posture Check Reminder** — periodic nudges to check your posture, with a one-tap "good / adjusted" log and daily stats.
- **Reports** — a week/month view across all three modules: a daily (or weekly, for month view) score against each module's goal, an overall verdict (Great / Good / Needs work / No data), and a "where to improve" callout naming the weakest area with a concrete tip.

## Architecture

- State management: `provider` (one `ChangeNotifier` per module).
- Persistence: `shared_preferences`, wrapped by `StorageService` for JSON (de)serialization.
- Reminders: `flutter_local_notifications` via `NotificationService`, scheduling recurring interval-based notifications per module.

```
lib/
  core/
    models/       # Plain data classes (HydrationEntry, WorkoutSet, PostureCheck)
    services/      # NotificationService, StorageService
    theme/         # App-wide Material 3 theme
  features/
    home/          # Dashboard + bottom navigation shell
    hydration/
    workout/
    posture/
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

## Getting started

```bash
flutter pub get
flutter run            # or: flutter run -d linux / -d chrome
flutter test
flutter analyze
```

### Android notifications

On Android 13+ and iOS, notification permission is requested automatically
on first app launch (see `main.dart`) so reminders can be scheduled.
