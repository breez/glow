import 'package:equatable/equatable.dart';

/// Represents the current state of the PIN setup flow
abstract class PinSetupState extends Equatable {
  const PinSetupState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - waiting for first PIN entry
class PinSetupInitial extends PinSetupState {
  const PinSetupInitial();
}

/// First PIN entered, waiting for confirmation
class PinSetupAwaitingConfirmation extends PinSetupState {
  final String firstPin;

  const PinSetupAwaitingConfirmation({required this.firstPin});

  @override
  List<Object?> get props => <Object?>[firstPin];
}

/// PIN saved successfully
class PinSetupSuccess extends PinSetupState {
  const PinSetupSuccess();
}

/// Error occurred during PIN setup
class PinSetupError extends PinSetupState {
  final String message;

  const PinSetupError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
