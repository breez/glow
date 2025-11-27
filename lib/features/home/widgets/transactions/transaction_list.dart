import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/features/home/widgets/transactions/providers/transaction_providers.dart';
import 'package:glow/features/home/widgets/transactions/transaction_list_layout.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/routing/app_routes.dart';

class TransactionList extends ConsumerWidget {
  final ScrollController? scrollController;
  const TransactionList({super.key, this.onTransactionTap, this.scrollController});

  final Function(Payment payment)? onTransactionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionListState state = ref.watch(transactionListStateProvider);

    return TransactionListLayout(
      scrollController: scrollController,
      state: state,
      onTransactionTap: (Payment payment) => _onTransactionTap(context, payment),
      onRetry: () {
        ref.invalidate(paymentsProvider);
      },
    );
  }

  void _onTransactionTap(BuildContext context, Payment payment) {
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.paymentDetails, arguments: payment);
  }
}
