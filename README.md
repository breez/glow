# glow

Flutter app showcasing [Breez SDK - Nodeless (Spark Implementation)](https://sdk-doc-spark.breez.technology/).

## Setup

Install dependencies:
```bash
flutter pub get
```

Generate code and mocks:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Create `secrets.json` in project root (gitignored):
```json
{
  "BREEZ_API_KEY": "your_api_key"
}
```

## Running

Development build:
```bash
flutter run --flavor dev --dart-define=ENV=dev --dart-define-from-file=secrets.json
```

Production build:
```bash
flutter run --flavor prod --dart-define=ENV=prod --dart-define-from-file=secrets.json
```

## Testing

Unit tests:
```bash
flutter test
```

Integration tests (requires device/emulator):
```bash
flutter test integration_test
```

## Building

Development:
```bash
flutter build apk --flavor dev --dart-define=ENV=dev --dart-define-from-file=secrets.json --release
flutter build ios --flavor dev --dart-define=ENV=dev --dart-define-from-file=secrets.json --release
```

Production:
```bash
flutter build apk --flavor prod --dart-define=ENV=prod --dart-define-from-file=secrets.json --release
flutter build ios --flavor prod --dart-define=ENV=prod --dart-define-from-file=secrets.json --release
```

## Flavors

The app uses two flavors with isolated secure storage:
- **dev** - Development builds (`com.breez.spark.glow.dev`)
- **prod** - Production builds (`com.breez.spark.glow`)

This prevents data conflicts between debug and release builds.