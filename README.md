# SubTrack

SubTrack is a Flutter app for tracking recurring subscriptions, spotting waste, and staying ahead of upcoming charges.

## What It Does

- Local sign up, sign in, sign out, and session persistence
- Create, view, edit, cancel, and delete subscriptions
- Dashboard with monthly spend, yearly projection, and upcoming charges
- Analytics by category with potential savings from unused services
- Local reminders for upcoming billing dates

## Product Flow

1. Create an account or sign in.
2. Add a subscription manually or start from a popular template.
3. Review active subscriptions on the dashboard and subscriptions tab.
4. Inspect savings and category spend in analytics.
5. Edit, cancel, mark as used, or delete subscriptions as needed.

## Tech Stack

- Flutter
- Dart
- `shared_preferences` for local persistence
- `flutter_local_notifications` for reminders
- `fl_chart` for analytics visuals

## Project Structure

```text
lib/
  main.dart
  models/
  screens/
  services/
  theme/
  widgets/
android/
assets/
```

## Getting Started

### Requirements

- Flutter SDK 3.x or newer
- Dart SDK 3.x or newer
- Android Studio or VS Code

### Install

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Build APK

```bash
flutter build apk --debug
```

The APK is generated in `build/app/outputs/flutter-apk/`.

## Current Status

- App launches successfully
- Basic navigation works
- CRUD works for subscriptions
- Session persists after restart on the same device

## Notes

This workspace is currently configured for local storage mode. Firebase is not connected in the current build, so cloud sync, Firebase Auth, and Firestore-backed data are not active yet.
