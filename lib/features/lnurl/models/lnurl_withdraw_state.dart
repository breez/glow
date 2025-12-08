import 'package:equatable/equatable.dart';

/// State for LNURL Withdraw flows
import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for LNURL Withdraw flows
sealed class LnurlWithdrawState extends Equatable implements PaymentFlowState {
  const LnurlWithdrawState();

  @override
  bool get isInitial => this is LnurlWithdrawInitial;
  @override
  bool get isPreparing => false;
  @override
  bool get isReady => false; // Initial is waiting for input, effectively ready to submit
  @override
  bool get isSending => this is LnurlWithdrawProcessing;
  @override
  bool get isSuccess => this is LnurlWithdrawSuccess;
  @override
  bool get isError => this is LnurlWithdrawError;
  @override
  String? get errorMessage => this is LnurlWithdrawError ? (this as LnurlWithdrawError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - waiting for user to input amount
class LnurlWithdrawInitial extends LnurlWithdrawState {
  final BigInt minWithdrawableMsat;
  final BigInt maxWithdrawableMsat;

  const LnurlWithdrawInitial({required this.minWithdrawableMsat, required this.maxWithdrawableMsat});

  @override
  List<Object?> get props => <Object?>[minWithdrawableMsat, maxWithdrawableMsat];
}

/// Withdrawing funds (processing)
class LnurlWithdrawProcessing extends LnurlWithdrawState {
  const LnurlWithdrawProcessing();
}

/// Withdrawal completed successfully
class LnurlWithdrawSuccess extends LnurlWithdrawState {
  const LnurlWithdrawSuccess();
}

/// Withdrawal failed
class LnurlWithdrawError extends LnurlWithdrawState {
  final String message;
  final String? technicalDetails;

  const LnurlWithdrawError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
