import 'package:flutter/material.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/features/home/widgets/transactions/widgets/transaction_list_widgets.dart';

/// Pure presentation widget for transaction list
class TransactionListLayout extends StatelessWidget {
  const TransactionListLayout({required this.state, super.key, this.onTransactionTap, this.onRetry});

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
      itemBuilder: (BuildContext context, int index) {
        final TransactionItemState transaction = state.transactions[index];
        return TransactionListItem(
          transaction: transaction,
          onTap: onTransactionTap != null ? () => onTransactionTap!(transaction.payment) : null,
        );
      },
    );
  }
}
