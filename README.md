# Cosmos

A space-themed productivity app built with Flutter. Tasks, a Pomodoro focus
timer, and a daily gratitude log — wrapped in an animated galaxy UI with
frosted-glass surfaces. All data is stored locally in SQLite; no servers.

## Features

- **Sign in** — lightweight local profile (no account/backend)
- **Today** — greeting, daily stats, activity streak, backup/restore
- **Tasks** — priority-coded, animated check-off, swipe to delete
- **Focus** — Pomodoro timer (25/15/5) with a gradient progress ring and a
  local notification when a session completes
- **Gratitude** — daily entries with a 17-week heatmap
- Animated starfield background, gradient theme, all built-in animations

## Tech

- Flutter + Dart, `sqflite` (raw SQL, no ORM)
- `flutter_local_notifications` + `timezone` for focus alerts
- Single-file screens in `lib/main.dart`; data layer in `lib/db.dart`;
  shared UI in `lib/cosmos_ui.dart`; notifications in `lib/notify.dart`

## Run

```bash
flutter pub get
flutter run
```

## Release build

Signing reads `android/key.properties` (kept out of git). With the upload
keystore in place:

```bash
flutter build appbundle   # build/app/outputs/bundle/release/app-release.aab
```

## Status

Personal/demo-grade. "Sync" is local JSON backup/restore — the foundation for
real cloud sync, which would need a backend (Supabase/Firebase).
