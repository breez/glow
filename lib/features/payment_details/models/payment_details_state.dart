import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';
import '../services/payment_formatter.dart';

/// State representation for payment details screen
class PaymentDetailsState extends Equatable {
  const PaymentDetailsState({
    required this.payment,
    required this.formattedAmount,
    required this.formattedFees,
    required this.formattedStatus,
    required this.formattedType,
    required this.formattedMethod,
    required this.formattedDate,
    required this.shouldShowFees,
  });

  final Payment payment;
  final String formattedAmount;
  final String formattedFees;
  final String formattedStatus;
  final String formattedType;
  final String formattedMethod;
  final String formattedDate;
  final bool shouldShowFees;

  @override
  List<Object?> get props => [
    payment.id,
    formattedAmount,
    formattedFees,
    formattedStatus,
    formattedType,
    formattedMethod,
    formattedDate,
    shouldShowFees,
  ];
}

/// Factory to create PaymentDetailsState from Payment
class PaymentDetailsStateFactory {
  const PaymentDetailsStateFactory(this.formatter);

  final PaymentFormatter formatter;

  PaymentDetailsState createState(Payment payment) {
    return PaymentDetailsState(
      payment: payment,
      formattedAmount: formatter.formatSats(payment.amount),
      formattedFees: formatter.formatSats(payment.fees),
      formattedStatus: formatter.formatStatus(payment.status),
      formattedType: formatter.formatType(payment.paymentType),
      formattedMethod: formatter.formatMethod(payment.method),
      formattedDate: formatter.formatDate(payment.timestamp),
      shouldShowFees: payment.fees > BigInt.zero,
    );
  }
}
