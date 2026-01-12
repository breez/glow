import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/transactions/models/transaction_list_state.dart';
import 'package:glow/features/transactions/providers/transaction_providers.dart';
import 'package:glow/features/transactions/transaction_list_layout.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/routing/app_routes.dart';

class TransactionList extends ConsumerWidget {
  final ScrollController? scrollController;
  const TransactionList({super.key, this.onTransactionTap, this.scrollController});

  final Function(Payment payment)? onTransactionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionListState state = ref.watch(transactionListStateProvider);
    final bool hasSynced = ref.watch(hasSyncedProvider);

    return TransactionListLayout(
      scrollController: scrollController,
      state: state,
      hasSynced: hasSynced,
      onTransactionTap: (TransactionItemState item) => _onTransactionTap(context, item),
      onRetry: () {
        ref.invalidate(paymentsProvider);
      },
    );
  }

  void _onTransactionTap(BuildContext context, TransactionItemState item) {
    if (!context.mounted) {
      return;
    }

    // Check if this is a pending deposit or regular payment
    if (item.isPendingDeposit) {
      // Navigate to deposit approval screen
      Navigator.of(context).pushNamed(AppRoutes.depositApproval, arguments: item.pendingDeposit!);
    } else {
      // Navigate to payment details screen
      Navigator.of(context).pushNamed(AppRoutes.paymentDetails, arguments: item.payment!);
    }
  }
}
