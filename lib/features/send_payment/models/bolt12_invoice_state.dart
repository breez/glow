import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for BOLT12 Invoice payment flows
sealed class Bolt12InvoiceState extends Equatable implements PaymentFlowState {
  const Bolt12InvoiceState();

  @override
  bool get isInitial => this is Bolt12InvoiceInitial;
  @override
  bool get isPreparing => this is Bolt12InvoicePreparing;
  @override
  bool get isReady => this is Bolt12InvoiceReady;
  @override
  bool get isSending => this is Bolt12InvoiceSending;
  @override
  bool get isSuccess => this is Bolt12InvoiceSuccess;
  @override
  bool get isError => this is Bolt12InvoiceError;
  @override
  String? get errorMessage =>
      this is Bolt12InvoiceError ? (this as Bolt12InvoiceError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no action taken yet
class Bolt12InvoiceInitial extends Bolt12InvoiceState {
  const Bolt12InvoiceInitial();
}

/// Preparing the payment (calculating fees)
class Bolt12InvoicePreparing extends Bolt12InvoiceState {
  const Bolt12InvoicePreparing();
}

/// Payment is prepared and ready to send
class Bolt12InvoiceReady extends Bolt12InvoiceState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;

  const Bolt12InvoiceReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
  });

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats];
}

/// Sending the payment
class Bolt12InvoiceSending extends Bolt12InvoiceState {
  final PrepareSendPaymentResponse prepareResponse;

  const Bolt12InvoiceSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class Bolt12InvoiceSuccess extends Bolt12InvoiceState {
  final Payment payment;

  const Bolt12InvoiceSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class Bolt12InvoiceError extends Bolt12InvoiceState {
  final String message;
  final String? technicalDetails;

  const Bolt12InvoiceError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
