import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/services/breez_sdk_service.dart';
import 'package:glow/features/developers/providers/max_deposit_fee_provider.dart';

/// Provider to list unclaimed deposits
final FutureProvider<List<DepositInfo>> unclaimedDepositsProvider = FutureProvider<List<DepositInfo>>((
  Ref ref,
) async {
  final BreezSdk sdk = await ref.watch(sdkProvider.future);
  final BreezSdkService service = ref.read(breezSdkServiceProvider);

  // Watch the event stream to know when to refresh
  // This creates a dependency on the stream but doesn't create circular invalidation
  ref.watch(sdkEventsStreamProvider);

  final List<DepositInfo> deposits = await service.listUnclaimedDeposits(sdk);
  if (deposits.isNotEmpty) {
    log.d('Unclaimed deposits: ${deposits.length}');
  }
  return deposits;
});

/// Check if there are any unclaimed deposits that need attention
final Provider<AsyncValue<bool>> hasUnclaimedDepositsProvider = Provider<AsyncValue<bool>>((Ref ref) {
  return ref.watch(unclaimedDepositsProvider).whenData((List<DepositInfo> deposits) {
    final bool hasUnclaimed = deposits.isNotEmpty;
    if (hasUnclaimed) {
      log.w('User has ${deposits.length} unclaimed deposits');
    }
    return hasUnclaimed;
  });
});

/// Get count of unclaimed deposits for UI display
final Provider<AsyncValue<int>> unclaimedDepositsCountProvider = Provider<AsyncValue<int>>((Ref ref) {
  return ref.watch(unclaimedDepositsProvider).whenData((List<DepositInfo> deposits) => deposits.length);
});

/// Manual deposit claiming provider (for retrying failed claims)
final FutureProviderFamily<ClaimDepositResponse, DepositInfo> claimDepositProvider = FutureProvider
    .autoDispose
    .family<ClaimDepositResponse, DepositInfo>((Ref ref, DepositInfo deposit) async {
      log.d('Manually claiming deposit: ${deposit.txid}:${deposit.vout}');
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);
      final MaxFee maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);

      final ClaimDepositResponse response = await service.claimDeposit(
        sdk,
        ClaimDepositRequest(txid: deposit.txid, vout: deposit.vout, maxFee: maxDepositClaimFee),
      );

      // Refresh UI only if data changed
      await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
      await ref.read(paymentsProvider.notifier).refreshIfChanged();
      ref.invalidate(unclaimedDepositsProvider);

      return response;
    });
