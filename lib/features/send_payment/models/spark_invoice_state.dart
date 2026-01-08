import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for Spark Invoice payment flows
sealed class SparkInvoiceState extends Equatable implements PaymentFlowState {
  const SparkInvoiceState();

  @override
  bool get isInitial => this is SparkInvoiceInitial;
  @override
  bool get isPreparing => this is SparkInvoicePreparing;
  @override
  bool get isReady => this is SparkInvoiceReady;
  @override
  bool get isSending => this is SparkInvoiceSending;
  @override
  bool get isSuccess => this is SparkInvoiceSuccess;
  @override
  bool get isError => this is SparkInvoiceError;
  @override
  String? get errorMessage =>
      this is SparkInvoiceError ? (this as SparkInvoiceError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no action taken yet
class SparkInvoiceInitial extends SparkInvoiceState {
  const SparkInvoiceInitial();
}

/// Preparing the payment (calculating fees)
class SparkInvoicePreparing extends SparkInvoiceState {
  const SparkInvoicePreparing();
}

/// Payment is prepared and ready to send
class SparkInvoiceReady extends SparkInvoiceState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;
  final String? tokenIdentifier;
  final String? description;

  const SparkInvoiceReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
    this.tokenIdentifier,
    this.description,
  });

  @override
  List<Object?> get props => <Object?>[
    prepareResponse,
    amountSats,
    feeSats,
    tokenIdentifier,
    description,
  ];
}

/// Sending the payment
class SparkInvoiceSending extends SparkInvoiceState {
  final PrepareSendPaymentResponse prepareResponse;

  const SparkInvoiceSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class SparkInvoiceSuccess extends SparkInvoiceState {
  final Payment payment;

  const SparkInvoiceSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class SparkInvoiceError extends SparkInvoiceState {
  final String message;
  final String? technicalDetails;

  const SparkInvoiceError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
