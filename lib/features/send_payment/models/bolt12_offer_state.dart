import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// State for BOLT12 Offer payment flows
sealed class Bolt12OfferState extends Equatable implements PaymentFlowState {
  const Bolt12OfferState();

  @override
  bool get isInitial => this is Bolt12OfferInitial;
  @override
  bool get isPreparing => this is Bolt12OfferPreparing;
  @override
  bool get isReady => this is Bolt12OfferReady;
  @override
  bool get isSending => this is Bolt12OfferSending;
  @override
  bool get isSuccess => this is Bolt12OfferSuccess;
  @override
  bool get isError => this is Bolt12OfferError;
  @override
  String? get errorMessage => this is Bolt12OfferError ? (this as Bolt12OfferError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - waiting for user to input amount
class Bolt12OfferInitial extends Bolt12OfferState {
  final BigInt? minAmountMsat;

  const Bolt12OfferInitial({this.minAmountMsat});

  @override
  List<Object?> get props => <Object?>[minAmountMsat];
}

/// Preparing the payment (calculating fees)
class Bolt12OfferPreparing extends Bolt12OfferState {
  const Bolt12OfferPreparing();
}

/// Payment is prepared and ready to send
class Bolt12OfferReady extends Bolt12OfferState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;

  const Bolt12OfferReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
  });

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats];
}

/// Sending the payment
class Bolt12OfferSending extends Bolt12OfferState {
  final PrepareSendPaymentResponse prepareResponse;

  const Bolt12OfferSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class Bolt12OfferSuccess extends Bolt12OfferState {
  final Payment payment;

  const Bolt12OfferSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class Bolt12OfferError extends Bolt12OfferState {
  final String message;
  final String? technicalDetails;

  const Bolt12OfferError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
