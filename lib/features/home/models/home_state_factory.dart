import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:glow/features/home/widgets/balance/models/balance_state.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';

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
  TransactionItemState createTransactionItemState(Payment payment) {
    final bool isReceive = payment.paymentType == PaymentType.receive;

    return TransactionItemState(
      payment: payment,
      formattedAmount: transactionFormatter.formatSats(payment.amount),
      formattedAmountWithSign: transactionFormatter.formatAmountWithSign(payment.amount, payment.paymentType),
      formattedTime: transactionFormatter.formatRelativeTime(payment.timestamp),
      formattedStatus: transactionFormatter.formatStatus(payment.status),
      formattedMethod: transactionFormatter.formatMethod(payment.method),
      description: transactionFormatter.getShortDescription(payment.details),
      isReceive: isReceive,
    );
  }

  /// Creates TransactionListState from list of Payments
  TransactionListState createTransactionListState({
    required List<Payment> payments,
    required bool hasSynced,
  }) {
    if (payments.isEmpty) {
      return TransactionListState.empty();
    }

    final List<TransactionItemState> transactionItems = payments
        .map((Payment payment) => createTransactionItemState(payment))
        .toList();

    return TransactionListState.loaded(transactions: transactionItems, hasSynced: hasSynced);
  }
}
