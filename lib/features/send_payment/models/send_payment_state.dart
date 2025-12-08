import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// Base class for all send payment states
sealed class SendPaymentState extends Equatable implements PaymentFlowState {
  const SendPaymentState();

  @override
  bool get isInitial => this is SendPaymentInitial;
  @override
  bool get isPreparing => this is SendPaymentPreparing;
  @override
  bool get isReady => this is SendPaymentReady;
  @override
  bool get isSending => this is SendPaymentSending;
  @override
  bool get isSuccess => this is SendPaymentSuccess;
  @override
  bool get isError => this is SendPaymentError;
  @override
  String? get errorMessage => this is SendPaymentError ? (this as SendPaymentError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no action taken yet
class SendPaymentInitial extends SendPaymentState {
  const SendPaymentInitial();
}

/// Preparing the payment (calculating fees, validating)
class SendPaymentPreparing extends SendPaymentState {
  const SendPaymentPreparing();
}

/// Payment is prepared and ready to send
class SendPaymentReady extends SendPaymentState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;
  final String? description;

  const SendPaymentReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
    this.description,
  });

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats, description];
}

/// Sending the payment
class SendPaymentSending extends SendPaymentState {
  final PrepareSendPaymentResponse prepareResponse;

  const SendPaymentSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class SendPaymentSuccess extends SendPaymentState {
  final Payment payment;

  const SendPaymentSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class SendPaymentError extends SendPaymentState {
  final String message;
  final String? technicalDetails;

  const SendPaymentError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
