import 'package:equatable/equatable.dart';

/// State for LNURL Auth flows
import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for LNURL Auth flows
sealed class LnurlAuthState extends Equatable implements PaymentFlowState {
  const LnurlAuthState();

  @override
  bool get isInitial => this is LnurlAuthInitial;
  @override
  bool get isPreparing => false; // Auth doesn't have a distinct preparing phase usually
  @override
  bool get isReady => false; // Initial is effectively ready
  @override
  bool get isSending => this is LnurlAuthProcessing;
  @override
  bool get isSuccess => this is LnurlAuthSuccess;
  @override
  bool get isError => this is LnurlAuthError;
  @override
  String? get errorMessage => this is LnurlAuthError ? (this as LnurlAuthError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - ready to authenticate
class LnurlAuthInitial extends LnurlAuthState {
  const LnurlAuthInitial();
}

/// Authenticating (processing)
class LnurlAuthProcessing extends LnurlAuthState {
  const LnurlAuthProcessing();
}

/// Authentication completed successfully
class LnurlAuthSuccess extends LnurlAuthState {
  const LnurlAuthSuccess();
}

/// Authentication failed
class LnurlAuthError extends LnurlAuthState {
  final String message;
  final String? technicalDetails;

  const LnurlAuthError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
