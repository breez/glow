import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/transaction_formatter.dart';
import 'package:glow/features/balance/models/balance_state.dart';
import 'package:glow/providers/sdk_provider.dart';

/// Provider for BalanceState
/// Converts raw balance from sdk_provider to formatted BalanceState
final Provider<BalanceState> balanceStateProvider = Provider<BalanceState>((Ref ref) {
  final TransactionFormatter formatter = const TransactionFormatter();
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

      final String formattedBalance = formatter.formatSats(balance);
      // TODO(erdemyerebasmaz): Add when fiat rate available
      final String? formattedFiat = null;
      // formattedFiat = formatter.formatFiat(balance, fiatRate.rate, fiatRate.symbol);

      return BalanceState.loaded(
        balance: balance,
        hasSynced: shouldWait ? hasSynced : true,
        formattedBalance: formattedBalance,
        formattedFiat: formattedFiat,
      );
    },
    loading: () => BalanceState.loading(),
    error: (Object error, _) => BalanceState.error(error.toString()),
  );
});
