# Claude Code Guidelines

## Project Overview

This is a Flutter mobile app using Riverpod for state management. See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architectural patterns.

## Key Patterns to Follow

### Feature-First Structure
```
lib/features/feature_name/
├── models/              # Domain models & State classes
├── providers/           # Riverpod Notifiers (Business Logic)
├── services/            # (Optional) Feature-specific services
├── widgets/             # Feature-specific UI components
├── feature_screen.dart  # The Container (Wiring)
└── feature_layout.dart  # The View (Rendering)
```

### Screen/Layout Pattern
- **Screen Widget (Container)**: Reads navigation args, sets up providers, returns Layout widget
- **Layout Widget (View)**: Rendering only, accepts state/data as arguments, no business logic

## Code Quality Rules

### Linter Compliance
Run `flutter analyze` before committing. Key rules:
- `always_specify_types` - Explicit types for variables, parameters, return values
- `always_declare_return_types` - All functions must have explicit return types
- `prefer_const_constructors` - Use const constructors wherever possible
- `require_trailing_commas` - Add trailing commas for better diffs
- `prefer_single_quotes` - Use single quotes for strings

### Widget Performance
**Never use helper methods in widgets** (e.g., `_buildHeader()`, `_buildRow()`):
- They are called on every rebuild
- They prevent Flutter optimizations
- Extract to separate widget classes instead (enables const constructors)

## Riverpod 3.0 Syntax

### Basic Notifier
```dart
final NotifierProvider<CounterNotifier, int> counterProvider =
  NotifierProvider<CounterNotifier, int>(CounterNotifier.new);

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
```

### Family Notifier
```dart
final NotifierProviderFamily<TodoNotifier, TodoState, String> todoProvider =
  NotifierProvider.autoDispose.family<TodoNotifier, TodoState, String>(
    TodoNotifier.new,
  );

class TodoNotifier extends Notifier<TodoState> {
  TodoNotifier(this.todoId);
  final String todoId;

  @override
  TodoState build() => TodoState.loading(todoId);
}
```

### AsyncNotifier Family
```dart
final AsyncNotifierProviderFamily<UserNotifier, User, int> userProvider =
  AsyncNotifierProvider.autoDispose.family<UserNotifier, User, int>(
    UserNotifier.new,
  );

class UserNotifier extends AsyncNotifier<User> {
  UserNotifier(this.userId);
  final int userId;

  @override
  Future<User> build() async => await fetchUser(userId);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchUser(userId));
  }
}
```

## Quick Reference

| Do | Don't |
|---|---|
| Use `Notifier<State>` / `AsyncNotifier<State>` | Use old `StateNotifier` |
| Use `NotifierProvider<N, S>(N.new)` | Use `StateNotifierProvider` |
| Extract widgets to separate classes | Use `_buildX()` helper methods |
| Specify explicit types everywhere | Rely on type inference |
| Use single quotes for strings | Use double quotes |
| Add trailing commas | Omit trailing commas |
