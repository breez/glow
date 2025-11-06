import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/features/home/widgets/transactions/providers/transaction_providers.dart';
import 'package:glow/features/home/widgets/transactions/transaction_list_layout.dart';
import 'package:glow/core/providers/sdk_provider.dart';

/// TransactionList widget - handles setup and dependency injection
/// - TransactionList: handles setup
/// - TransactionListLayout: pure presentation widget
class TransactionList extends ConsumerWidget {
  const TransactionList({super.key, this.onTransactionTap});

  final Function(Payment payment)? onTransactionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get formatted state from provider
    final state = ref.watch(transactionListStateProvider);

    // Return pure presentation widget
    return TransactionListLayout(
      state: state,
      onTransactionTap: (payment) => _onTransactionTap(context, payment),
      onRetry: () {
        // Invalidate providers to retry
        ref.invalidate(paymentsProvider);
      },
    );
  }

  /// Pops navigation with result
  void _onTransactionTap(BuildContext context, Payment payment) {
    if (!context.mounted) return;

    Navigator.of(context).pushNamed(AppRoutes.paymentDetails, arguments: payment);
  }
}
