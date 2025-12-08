import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

/// State for BOLT12 Invoice Request payment flows
sealed class Bolt12InvoiceRequestState extends Equatable {
  const Bolt12InvoiceRequestState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - waiting for user to input amount
class Bolt12InvoiceRequestInitial extends Bolt12InvoiceRequestState {
  final BigInt? minAmountMsat;

  const Bolt12InvoiceRequestInitial({this.minAmountMsat});

  @override
  List<Object?> get props => <Object?>[minAmountMsat];
}

/// Preparing the payment (calculating fees)
class Bolt12InvoiceRequestPreparing extends Bolt12InvoiceRequestState {
  const Bolt12InvoiceRequestPreparing();
}

/// Payment is prepared and ready to send
class Bolt12InvoiceRequestReady extends Bolt12InvoiceRequestState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;

  const Bolt12InvoiceRequestReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
  });

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats];
}

/// Sending the payment
class Bolt12InvoiceRequestSending extends Bolt12InvoiceRequestState {
  final PrepareSendPaymentResponse prepareResponse;

  const Bolt12InvoiceRequestSending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class Bolt12InvoiceRequestSuccess extends Bolt12InvoiceRequestState {
  final Payment payment;

  const Bolt12InvoiceRequestSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class Bolt12InvoiceRequestError extends Bolt12InvoiceRequestState {
  final String message;
  final String? technicalDetails;

  const Bolt12InvoiceRequestError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
