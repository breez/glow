import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/models/home_state_factory.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';
import 'package:glow/features/home/providers/home_providers.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/core/providers/sdk_provider.dart';

/// Provider for TransactionFormatter service
final Provider<TransactionFormatter> transactionFormatterProvider = Provider<TransactionFormatter>((Ref ref) {
  return const TransactionFormatter();
});

/// Provider for TransactionListState
/// Converts raw payments from sdk_provider to formatted TransactionListState
final Provider<TransactionListState> transactionListStateProvider = Provider<TransactionListState>((Ref ref) {
  final HomeStateFactory factory = ref.watch(homeStateFactoryProvider);
  final AsyncValue<List<Payment>> paymentsAsync = ref.watch(paymentsProvider);
  final bool shouldWait = ref.watch(shouldWaitForInitialSyncProvider);
  final bool hasSynced = ref.watch(hasSyncedProvider);

  return paymentsAsync.when(
    data: (List<Payment> payments) => factory.createTransactionListState(
      payments: payments,
      hasSynced: shouldWait ? hasSynced : true,
      isLoading: false,
    ),
    loading: () => TransactionListState.loading(),
    error: (Object error, _) => TransactionListState.error(error.toString()),
  );
});
