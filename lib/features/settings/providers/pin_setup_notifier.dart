import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/settings/models/pin_setup_state.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/services/pin_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('PinSetupNotifier');

enum PinMode { setup, lock }

/// Notifier for managing PIN setup and lock flows
/// Single notifier handles both creating new PIN and verifying existing PIN
class PinSetupNotifier extends Notifier<PinSetupState> {
  late final PinService _pinService;
  PinMode _mode = PinMode.setup;

  @override
  PinSetupState build() {
    _pinService = ref.watch(pinServiceProvider);
    // Default to setup mode; can be overridden via family parameter
    return const PinSetupInitial();
  }

  /// Initialize notifier with specific mode (setup or lock)
  void initializeMode(PinMode mode) {
    _mode = mode;
    state = const PinSetupInitial();
  }

  /// Called when user enters a PIN
  Future<void> onPinEntered(String pin) async {
    final PinSetupState currentState = state;

    if (_mode == PinMode.setup) {
      _handleSetupMode(pin, currentState);
    } else if (_mode == PinMode.lock) {
      _handleLockMode(pin);
    }
  }

  /// Handle setup flow: entry → confirmation → save
  void _handleSetupMode(String pin, PinSetupState currentState) {
    // First PIN entry
    if (currentState is PinSetupInitial || currentState is PinSetupError) {
      state = PinSetupAwaitingConfirmation(firstPin: pin);
      return;
    }

    // Confirmation PIN entry
    if (currentState is PinSetupAwaitingConfirmation) {
      if (pin == currentState.firstPin) {
        _savePin(pin);
      } else {
        state = const PinSetupError(message: 'PIN does not match');
      }
    }
  }

  /// Handle lock mode: verify existing PIN only
  Future<void> _handleLockMode(String pin) async {
    try {
      final bool isValid = await _pinService.verifyPin(pin);
      if (isValid) {
        log.d('PIN verification succeeded');
        state = const PinSetupSuccess();
      } else {
        log.w('PIN verification failed');
        state = const PinSetupError(message: 'Incorrect PIN');
      }
    } catch (e) {
      log.e('Failed to verify PIN', error: e);
      state = PinSetupError(message: 'Error: $e');
    }
  }

  /// Save PIN to secure storage (setup mode only)
  Future<void> _savePin(String pin) async {
    try {
      await _pinService.setPin(pin);
      state = const PinSetupSuccess();
    } catch (e) {
      log.e('Failed to save PIN', error: e);
      state = PinSetupError(message: 'Failed to set PIN: $e');
    }
  }

  /// Clear error message by returning to initial state
  void clearError() {
    if (state is PinSetupError) {
      state = const PinSetupInitial();
    }
  }

  /// Reset to initial state
  void reset() {
    state = const PinSetupInitial();
  }
}

/// Provider for PIN setup notifier
final NotifierProvider<PinSetupNotifier, PinSetupState> pinSetupNotifierProvider =
    NotifierProvider<PinSetupNotifier, PinSetupState>(PinSetupNotifier.new);
