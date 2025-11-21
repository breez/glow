import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:glow/features/home/widgets/balance/models/balance_state.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';
import 'package:glow/features/profile/models/profile.dart';

/// Factory for creating home-related states
class HomeStateFactory {
  const HomeStateFactory({required this.transactionFormatter});

  final TransactionFormatter transactionFormatter;

  /// Creates BalanceState from raw balance value
  BalanceState createBalanceState({
    required BigInt balance,
    required bool hasSynced,
    double? exchangeRate,
    String? currencySymbol,
  }) {
    final String formattedBalance = transactionFormatter.formatSats(balance);
    final String? formattedFiat = (exchangeRate != null && currencySymbol != null)
        ? transactionFormatter.formatFiat(balance, exchangeRate, currencySymbol)
        : null;

    return BalanceState.loaded(
      balance: balance,
      hasSynced: hasSynced,
      formattedBalance: formattedBalance,
      formattedFiat: formattedFiat,
    );
  }

  /// Creates TransactionItemState from Payment
  TransactionItemState createTransactionItemState(Payment payment, {Profile? profile}) {
    final bool isReceive = payment.paymentType == PaymentType.receive;
    final String description = transactionFormatter.getShortDescription(payment.details);

    // Show profile for incoming payments without custom description
    final bool hasCustomDescription = _hasCustomDescription(payment.details);

    return TransactionItemState(
      payment: payment,
      formattedAmount: transactionFormatter.formatSats(payment.amount),
      formattedAmountWithSign: transactionFormatter.formatAmountWithSign(payment.amount, payment.paymentType),
      formattedTime: transactionFormatter.formatRelativeTime(payment.timestamp),
      formattedStatus: transactionFormatter.formatStatus(payment.status),
      formattedMethod: transactionFormatter.formatMethod(payment.method),
      description: description,
      isReceive: isReceive,
      profile: (isReceive && !hasCustomDescription) ? profile : null,
    );
  }

  /// Checks if payment has a custom user-provided description
  bool _hasCustomDescription(PaymentDetails? details) {
    if (details == null) {
      return false;
    }

    return switch (details) {
      PaymentDetails_Lightning(:final String? description) =>
        description != null && description.isNotEmpty && description != 'Payment',
      PaymentDetails_Token() => true, // Token name is meaningful
      PaymentDetails_Deposit() => false, // Generic deposit
      PaymentDetails_Withdraw() => false, // Generic withdrawal
      PaymentDetails_Spark() => false, // Generic spark payment
    };
  }

  /// Creates TransactionListState from list of Payments
  TransactionListState createTransactionListState({
    required List<Payment> payments,
    required bool hasSynced,
    Profile? profile,
  }) {
    if (payments.isEmpty) {
      return TransactionListState.empty();
    }

    final List<TransactionItemState> transactionItems = payments
        .map((Payment payment) => createTransactionItemState(payment, profile: profile))
        .toList();

    return TransactionListState.loaded(transactions: transactionItems, hasSynced: hasSynced);
  }
}
