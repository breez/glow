import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

/// Payment-related helper functions

/// Extracts a user-friendly title from a Payment object based on its details
///
/// Returns appropriate titles for different payment types:
/// - Spark payments
/// - Token payments (uses token name)
/// - Lightning payments (uses description if available)
/// - Withdrawals and deposits
String getPaymentTitle(Payment payment) {
  final PaymentDetails? details = payment.details;
  if (details == null) {
    return 'Payment';
  }

  return switch (details) {
    PaymentDetails_Spark() => 'Spark Payment',
    PaymentDetails_Token(:final TokenMetadata metadata) => metadata.name,
    PaymentDetails_Lightning(:final String? description) =>
      description?.isNotEmpty == true ? description! : 'Lightning Payment',
    PaymentDetails_Withdraw() => 'Withdrawal',
    PaymentDetails_Deposit() => 'Deposit',
  };
}
