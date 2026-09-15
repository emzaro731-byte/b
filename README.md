# Veylola AI

Flutter AI application using Firebase as the backend.

Firebase project: `emma-f716b`

## Architecture

Flutter → Firebase Auth / Firestore / Storage → Cloud Functions → AI providers

AI provider secrets must remain server-side and must never be embedded in the Flutter application.

## Firebase configuration

From the project root, run:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=emma-f716b
```

FlutterFire generates `lib/firebase_options.dart` for the selected platforms.

See the official Firebase Flutter setup documentation for the current configuration process.
