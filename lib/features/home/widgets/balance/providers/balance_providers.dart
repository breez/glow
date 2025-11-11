import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/widgets/balance/models/balance_state.dart';
import 'package:glow/features/home/providers/home_providers.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';

/// Provider for BalanceFormatter service
final balanceFormatterProvider = Provider<TransactionFormatter>((ref) {
  return const TransactionFormatter();
});

/// Provider for BalanceState
/// Converts raw balance from sdk_provider to formatted BalanceState
final balanceStateProvider = Provider<BalanceState>((ref) {
  final factory = ref.watch(homeStateFactoryProvider);
  final balanceAsync = ref.watch(balanceProvider);

  final shouldWait = ref.watch(shouldWaitForInitialSyncProvider);
  final hasSynced = ref.watch(hasSyncedProvider);

  // TODO: Add fiat rate support when available
  // final fiatRate = ref.watch(fiatRateProvider);

  return balanceAsync.when(
    data: (balance) => factory.createBalanceState(
      balance: balance,
      hasSynced: shouldWait ? hasSynced : true,
      isLoading: false,
      // exchangeRate: fiatRate?.rate,
      // currencySymbol: fiatRate?.symbol,
    ),
    loading: () => BalanceState.loading(),
    error: (error, _) => BalanceState.error(error.toString()),
  );
});
