import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/models/home_state_factory.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';
import 'package:glow/features/home/providers/home_providers.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/features/profile/models/profile.dart';

/// Provider for TransactionFormatter service
final Provider<TransactionFormatter> transactionFormatterProvider = Provider<TransactionFormatter>((Ref ref) {
  return const TransactionFormatter();
});

/// Provider for TransactionListState
/// Converts raw payments from sdk_provider to formatted TransactionListState
final Provider<TransactionListState> transactionListStateProvider = Provider<TransactionListState>((Ref ref) {
  final HomeStateFactory factory = ref.watch(homeStateFactoryProvider);
  final AsyncValue<List<Payment>> paymentsAsync = ref.watch(paymentsProvider);
  final AsyncValue<WalletMetadata?> activeWallet = ref.watch(activeWalletProvider);

  final AsyncValue<bool> shouldWaitAsync = ref.watch(shouldWaitForInitialSyncProvider);
  final bool hasSynced = ref.watch(hasSyncedProvider);

  return paymentsAsync.when(
    data: (List<Payment> payments) {
      // If payments are loaded, show them immediately
      // Only check sync status if we're still determining whether to wait
      final bool shouldWait = shouldWaitAsync.hasValue ? shouldWaitAsync.value! : false;
      final Profile? profile = activeWallet.value?.profile;
      return factory.createTransactionListState(
        payments: payments,
        hasSynced: shouldWait ? hasSynced : true,
        profile: profile,
      );
    },
    loading: () => TransactionListState.loading(),
    error: (Object error, _) => TransactionListState.error(error.toString()),
  );
});
