import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/models/home_state_factory.dart';
import 'package:glow/features/home/providers/home_providers.dart';
import 'package:glow/features/home/widgets/transaction_filter/transaction_filter_provider.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/providers/sdk_provider.dart';

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
  final TransactionFilterState filterState = ref.watch(transactionFilterProvider);

  final AsyncValue<bool> shouldWaitAsync = ref.watch(shouldWaitForInitialSyncProvider);
  final bool hasSynced = ref.watch(hasSyncedProvider);

  return paymentsAsync.when(
    data: (List<Payment> payments) {
      final bool hasActiveFilter =
          filterState.paymentTypes.isNotEmpty || filterState.startDate != null || filterState.endDate != null;

      final List<Payment> filteredPayments = payments.where((Payment payment) {
        // Convert payment timestamp to DateTime for comparison
        final DateTime paymentDate = DateTime.fromMillisecondsSinceEpoch(payment.timestamp.toInt() * 1000);

        final bool afterStartDate =
            filterState.startDate == null || paymentDate.isAfter(filterState.startDate!);
        final bool beforeEndDate = filterState.endDate == null || paymentDate.isBefore(filterState.endDate!);
        final bool ofPaymentType =
            filterState.paymentTypes.isEmpty || filterState.paymentTypes.contains(payment.paymentType);

        return afterStartDate && beforeEndDate && ofPaymentType;
      }).toList();

      final bool shouldWait = shouldWaitAsync.hasValue ? shouldWaitAsync.value! : false;
      final Profile? profile = activeWallet.value?.profile;

      // If a filter is active, we consider it "synced" to avoid showing a loading spinner for an empty list.
      return factory.createTransactionListState(
        payments: filteredPayments,
        hasSynced: hasActiveFilter ? true : (shouldWait ? hasSynced : true),
        profile: profile,
        hasActiveFilter: hasActiveFilter,
      );
    },
    loading: () => TransactionListState.loading(),
    error: (Object error, _) => TransactionListState.error(error.toString()),
  );
});
