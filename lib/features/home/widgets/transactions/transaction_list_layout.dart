import 'package:flutter/material.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'models/transaction_list_state.dart';
import 'widgets/transaction_list_widgets.dart';

/// Pure presentation widget for transaction list
/// Following Visual Layout Widget principle - only converts state to widgets
class TransactionListLayout extends StatelessWidget {
  const TransactionListLayout({super.key, required this.state, this.onTransactionTap, this.onRetry});

  final TransactionListState state;
  final Function(Payment payment)? onTransactionTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const TransactionListLoading();
    }

    if (state.hasError) {
      return TransactionListError(error: state.error!, onRetry: onRetry);
    }

    if (state.isEmpty) {
      return const TransactionListEmpty();
    }

    return _buildTransactionList(context);
  }

  Widget _buildTransactionList(BuildContext context) {
    return ListView.builder(
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final transaction = state.transactions[index];
        return TransactionListItem(
          transaction: transaction,
          onTap: onTransactionTap != null ? () => onTransactionTap!(transaction.payment) : null,
        );
      },
    );
  }
}
