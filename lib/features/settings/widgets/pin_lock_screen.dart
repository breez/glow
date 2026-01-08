import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/settings/models/pin_setup_state.dart';
import 'package:glow/features/settings/providers/pin_setup_notifier.dart';
import 'package:glow/features/settings/widgets/pin_setup_layout.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('PinLockScreen');

/// PIN lock screen - verifies existing PIN
/// Reuses PinSetupState and PinEntryWidget, configured in lock mode
class PinLockScreen extends ConsumerStatefulWidget {
  /// Optional callback on successful unlock
  final VoidCallback? onUnlocked;

  /// Whether to pop the screen on successful unlock (default true)
  final bool popOnSuccess;

  const PinLockScreen({this.onUnlocked, this.popOnSuccess = true, super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  @override
  void initState() {
    super.initState();
    // Reset and configure notifier for lock mode
    Future<void>.microtask(() {
      ref.read(pinSetupNotifierProvider.notifier)
        ..initializeMode(PinMode.lock)
        ..reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final PinSetupState state = ref.watch(pinSetupNotifierProvider);
    log.d('PinLockScreen building with state: ${state.runtimeType}');

    // Handle successful unlock
    ref.listen<PinSetupState>(pinSetupNotifierProvider, (
      PinSetupState? previous,
      PinSetupState current,
    ) {
      log.d('State changed to ${current.runtimeType}');
      if (current is PinSetupSuccess) {
        widget.onUnlocked?.call();
        if (widget.popOnSuccess) {
          Navigator.pop(context);
        }
      }
    });

    return PopScope(
      canPop: !widget.popOnSuccess, // Prevent back button
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: !widget.popOnSuccess),
        body: SafeArea(
          child: PinSetupLayout(
            state: state,
            onPinEntered: (String pin) =>
                ref.read(pinSetupNotifierProvider.notifier).onPinEntered(pin),
            onInputStarted: () => ref.read(pinSetupNotifierProvider.notifier).clearError(),
            label: 'Enter your PIN',
          ),
        ),
      ),
    );
  }
}
