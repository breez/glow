import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

/// Tracking state for incoming payments
sealed class PaymentTrackingState extends Equatable {
  const PaymentTrackingState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Not tracking any payment
class NotTrackingPayment extends PaymentTrackingState {
  const NotTrackingPayment();
}

/// Tracking payments (waiting for incoming payment)
class TrackingPayment extends PaymentTrackingState {
  const TrackingPayment({this.expectedPaymentHash});

  /// Expected payment hash for invoice-based tracking (null for Lightning Address)
  final String? expectedPaymentHash;

  @override
  List<Object?> get props => <Object?>[expectedPaymentHash];
}

/// Payment received successfully
class PaymentReceived extends PaymentTrackingState {
  const PaymentReceived({required this.payment});

  final Payment payment;

  @override
  List<Object?> get props => <Object?>[payment.id];
}
