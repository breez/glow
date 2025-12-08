import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for BOLT11 payment flows
sealed class Bolt11PaymentState extends Equatable implements PaymentFlowState {
  const Bolt11PaymentState();

  @override
  bool get isInitial => this is Bolt11PaymentInitial;
  @override
  bool get isPreparing => this is Bolt11PaymentPreparing;
  @override
  bool get isReady => this is Bolt11PaymentReady;
  @override
  bool get isSending => this is Bolt11PaymentSending;
  @override
  bool get isSuccess => this is Bolt11PaymentSuccess;
  @override
  bool get isError => this is Bolt11PaymentError;
  @override
  String? get errorMessage => this is Bolt11PaymentError ? (this as Bolt11PaymentError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no action taken yet
class Bolt11PaymentInitial extends Bolt11PaymentState {
  const Bolt11PaymentInitial();
}

/// Preparing the payment (calculating fees, validating)
class Bolt11PaymentPreparing extends Bolt11PaymentState {
  const Bolt11PaymentPreparing();
}

/// Payment is prepared and ready to send
class Bolt11PaymentReady extends Bolt11PaymentState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;
  final String? description;

  const Bolt11PaymentReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
    this.description,
  });

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats, description];
}

/// Sending the payment
class Bolt11PaymentSending extends Bolt11PaymentState {
  final PrepareSendPaymentResponse prepareResponse;

  const Bolt11PaymentSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class Bolt11PaymentSuccess extends Bolt11PaymentState {
  final Payment payment;

  const Bolt11PaymentSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class Bolt11PaymentError extends Bolt11PaymentState {
  final String message;
  final String? technicalDetails;

  const Bolt11PaymentError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
