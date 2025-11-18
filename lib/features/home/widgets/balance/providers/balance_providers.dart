import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/models/home_state_factory.dart';
import 'package:glow/features/home/widgets/balance/models/balance_state.dart';
import 'package:glow/features/home/providers/home_providers.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:glow/features/home/widgets/transactions/services/transaction_formatter.dart';

/// Provider for BalanceFormatter service
final Provider<TransactionFormatter> balanceFormatterProvider = Provider<TransactionFormatter>((Ref ref) {
  return const TransactionFormatter();
});

/// Provider for BalanceState
/// Converts raw balance from sdk_provider to formatted BalanceState
final Provider<BalanceState> balanceStateProvider = Provider<BalanceState>((Ref ref) {
  final HomeStateFactory factory = ref.watch(homeStateFactoryProvider);
  final AsyncValue<BigInt> balanceAsync = ref.watch(balanceProvider);

  final AsyncValue<bool> shouldWaitAsync = ref.watch(shouldWaitForInitialSyncProvider);
  final bool hasSynced = ref.watch(hasSyncedProvider);

  // TODO(erdemyerebasmaz): Add fiat rate support when available
  // final fiatRate = ref.watch(fiatRateProvider);

  return balanceAsync.when(
    data: (BigInt balance) {
      // If balance is loaded, show it immediately
      // Only check sync status if we're still determining whether to wait
      final bool shouldWait = shouldWaitAsync.hasValue ? shouldWaitAsync.value! : false;
      return factory.createBalanceState(
        balance: balance,
        hasSynced: shouldWait ? hasSynced : true,
        // exchangeRate: fiatRate?.rate,
        // currencySymbol: fiatRate?.symbol,
      );
    },
    loading: () => BalanceState.loading(),
    error: (Object error, _) => BalanceState.error(error.toString()),
  );
});
