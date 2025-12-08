import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for Silent Payment Address flows
sealed class SilentPaymentState extends Equatable implements PaymentFlowState {
  const SilentPaymentState();

  @override
  bool get isInitial => this is SilentPaymentInitial;
  @override
  bool get isPreparing => this is SilentPaymentPreparing;
  @override
  bool get isReady => this is SilentPaymentReady;
  @override
  bool get isSending => this is SilentPaymentSending;
  @override
  bool get isSuccess => this is SilentPaymentSuccess;
  @override
  bool get isError => this is SilentPaymentError;
  @override
  String? get errorMessage => this is SilentPaymentError ? (this as SilentPaymentError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no action taken yet
class SilentPaymentInitial extends SilentPaymentState {
  const SilentPaymentInitial();
}

/// Preparing the payment (calculating fees)
class SilentPaymentPreparing extends SilentPaymentState {
  const SilentPaymentPreparing();
}

/// Payment is prepared and ready to send
class SilentPaymentReady extends SilentPaymentState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;

  const SilentPaymentReady({required this.prepareResponse, required this.amountSats, required this.feeSats});

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats];
}

/// Sending the payment
class SilentPaymentSending extends SilentPaymentState {
  final PrepareSendPaymentResponse prepareResponse;

  const SilentPaymentSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class SilentPaymentSuccess extends SilentPaymentState {
  final Payment payment;

  const SilentPaymentSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class SilentPaymentError extends SilentPaymentState {
  final String message;
  final String? technicalDetails;

  const SilentPaymentError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
