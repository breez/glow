import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for Spark Address payment flows
sealed class SparkAddressState extends Equatable implements PaymentFlowState {
  const SparkAddressState();

  @override
  bool get isInitial => this is SparkAddressInitial;
  @override
  bool get isPreparing => this is SparkAddressPreparing;
  @override
  bool get isReady => this is SparkAddressReady;
  @override
  bool get isSending => this is SparkAddressSending;
  @override
  bool get isSuccess => this is SparkAddressSuccess;
  @override
  bool get isError => this is SparkAddressError;
  @override
  String? get errorMessage => this is SparkAddressError ? (this as SparkAddressError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no action taken yet
class SparkAddressInitial extends SparkAddressState {
  const SparkAddressInitial();
}

/// Preparing the payment (calculating fees)
class SparkAddressPreparing extends SparkAddressState {
  const SparkAddressPreparing();
}

/// Payment is prepared and ready to send
class SparkAddressReady extends SparkAddressState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;
  final String? tokenIdentifier;

  const SparkAddressReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
    this.tokenIdentifier,
  });

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats, tokenIdentifier];
}

/// Sending the payment
class SparkAddressSending extends SparkAddressState {
  final PrepareSendPaymentResponse prepareResponse;

  const SparkAddressSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class SparkAddressSuccess extends SparkAddressState {
  final Payment payment;

  const SparkAddressSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class SparkAddressError extends SparkAddressState {
  final String message;
  final String? technicalDetails;

  const SparkAddressError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
