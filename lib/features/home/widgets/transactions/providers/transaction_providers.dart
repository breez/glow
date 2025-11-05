import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';
import 'package:glow/features/home/providers/home_providers.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/providers/sdk_provider.dart';

/// Provider for TransactionFormatter service
final transactionFormatterProvider = Provider<TransactionFormatter>((ref) {
  return const TransactionFormatter();
});

/// Provider for TransactionListState
/// Converts raw payments from sdk_provider to formatted TransactionListState
final transactionListStateProvider = Provider<TransactionListState>((ref) {
  final factory = ref.watch(homeStateFactoryProvider);
  final paymentsAsync = ref.watch(paymentsProvider);
  final shouldWait = ref.watch(shouldWaitForInitialSyncProvider);
  final hasSynced = ref.watch(hasSyncedProvider);

  return paymentsAsync.when(
    data: (payments) => factory.createTransactionListState(
      payments: payments,
      hasSynced: shouldWait ? hasSynced : true,
      isLoading: false,
    ),
    loading: () => TransactionListState.loading(),
    error: (error, _) => TransactionListState.error(error.toString()),
  );
});
