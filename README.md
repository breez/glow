# glow_breez

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

## Running Tests

Unit tests:
```bash
flutter test
```

Integration tests (requires connected device or emulator):
```bash
flutter test integration_test
```
