import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:glow/core/services/breez_sdk_service.dart';
import 'package:glow/features/developers/providers/max_deposit_fee_provider.dart';

/// Provider to list unclaimed deposits
final unclaimedDepositsProvider = FutureProvider<List<DepositInfo>>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);

  // Watch the event stream to know when to refresh
  // This creates a dependency on the stream but doesn't create circular invalidation
  ref.watch(sdkEventsStreamProvider);

  final deposits = await service.listUnclaimedDeposits(sdk);
  if (deposits.isNotEmpty) {
    log.d('Unclaimed deposits: ${deposits.length}');
  }
  return deposits;
});

/// Check if there are any unclaimed deposits that need attention
final hasUnclaimedDepositsProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(unclaimedDepositsProvider).whenData((deposits) {
    final hasUnclaimed = deposits.isNotEmpty;
    if (hasUnclaimed) {
      log.w('User has ${deposits.length} unclaimed deposits');
    }
    return hasUnclaimed;
  });
});

/// Get count of unclaimed deposits for UI display
final unclaimedDepositsCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(unclaimedDepositsProvider).whenData((deposits) => deposits.length);
});

/// Manual deposit claiming provider (for retrying failed claims)
final claimDepositProvider = FutureProvider.autoDispose.family<ClaimDepositResponse, DepositInfo>((
  ref,
  deposit,
) async {
  log.d('Manually claiming deposit: ${deposit.txid}:${deposit.vout}');
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);
  final maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);

  final response = await service.claimDeposit(
    sdk,
    ClaimDepositRequest(txid: deposit.txid, vout: deposit.vout, maxFee: maxDepositClaimFee),
  );

  // Refresh UI only if data changed
  await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
  await ref.read(paymentsProvider.notifier).refreshIfChanged();
  ref.invalidate(unclaimedDepositsProvider);

  return response;
});
