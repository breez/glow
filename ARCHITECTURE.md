# Architectural Guidelines

To ensure maintainability, testability, and scalability, we follow strict Separation of Concerns (SoC) principles and a custom Feature-First architecture.

## 1. Feature-First Structure (The "Twist")
We organize code by **feature**, but with a flattened internal structure compared to standard Clean Architecture.

### Directory Structure
```
lib/features/feature_name/
├── models/           # Domain models & State classes
├── providers/        # Riverpod Notifiers (Business Logic)
├── services/         # (Optional) Feature-specific services
├── widgets/          # Feature-specific UI components
├── feature_screen.dart # The Container (Wiring)
└── feature_layout.dart # The View (Rendering)
```

### Layers
- **Presentation**: `widgets/`, `feature_screen.dart`, `feature_layout.dart`.
- **Application/Logic**: `providers/`. Notifiers handle user flows, state updates, and service calls.
- **Data/Core**: `lib/core/services/`. Shared services (e.g., `BreezSdkService`) are accessed by providers.

## 2. Separation of Concerns (SoC)

### Inversion of Control (IoC)
- **Do not instantiate dependencies** inside widgets.
- **Inject dependencies** using Riverpod.

### State Management
- **Separate business logic from UI code.**
- Use dedicated State objects (simple immutable classes with `equatable`) to represent the UI state.
- Use `Notifier` / `AsyncNotifier` to handle logic.
- Widgets should only *consume* state.

### Visual Dedicated Layout Widgets
Split "Screens" into two distinct widgets:

#### A. The Screen Widget (The "Container")
- **Responsibility**: Wiring and Configuration.
- Reads navigation arguments.
- Sets up Providers/Notifiers.
- Returns the `Layout` widget.
- **Example**: `WalletImportScreen`

#### B. The Layout Widget (The "View")
- **Responsibility**: Rendering only.
- Accepts state/data as arguments.
- **No business logic.**
- **Example**: `WalletImportLayout`

## Example Structure

```dart
// 1. The Screen (Container)
class DetailScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final state = ref.watch(detailControllerProvider(id));
    
    return DetailLayout(
      state: state,
      onRefresh: () => ref.read(detailControllerProvider(id).notifier).refresh(),
    );
  }
}

// 2. The Layout (View)
class DetailLayout extends StatelessWidget {
  final DetailState state;
  final VoidCallback onRefresh;

  const DetailLayout({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(state.title)),
      body: state.isLoading 
          ? const CircularProgressIndicator()
          : Text(state.data),
      floatingActionButton: FloatingActionButton(onPressed: onRefresh),
    );
  }
}
```
