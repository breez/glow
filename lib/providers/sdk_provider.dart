import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/services/breez_sdk_service.dart';
import 'package:glow/services/config_service.dart';
import 'package:glow/services/wallet_storage_service.dart';

final log = AppLogger.getLogger('SdkProvider');

/// Network selection state
class NetworkNotifier extends Notifier<Network> {
  @override
  Network build() {
    log.d('NetworkNotifier initialized with mainnet');
    return Network.mainnet;
  }

  void setNetwork(Network network) {
    log.d('Changing network to $network from $state');
    state = network;
    log.d('Network state updated to $state');
  }
}

final networkProvider = NotifierProvider<NetworkNotifier, Network>(NetworkNotifier.new);

/// Track if Lightning Address was manually deleted (to prevent auto-registration)
class LightningAddressManuallyDeletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    log.d('LightningAddressManuallyDeletedNotifier initialized');
    // Reset when wallet changes
    ref.listen(activeWalletProvider, (previous, next) {
      if (previous?.value?.id != next.value?.id) {
        log.d('Wallet changed, resetting LightningAddressManuallyDeleted state');
        state = false;
      }
    });
    return false;
  }

  void markAsDeleted() {
    log.d('Lightning address manually marked as deleted');
    state = true;
  }

  void reset() {
    log.d('Lightning address manual delete state reset');
    state = false;
  }
}

final lightningAddressManuallyDeletedProvider =
    NotifierProvider<LightningAddressManuallyDeletedNotifier, bool>(
      LightningAddressManuallyDeletedNotifier.new,
    );

/// Connected SDK instance - auto-reconnects on wallet/network changes
final sdkProvider = FutureProvider<BreezSdk>((ref) async {
  log.d('sdkProvider initializing');
  final walletId = ref.watch(activeWalletIdProvider);
  log.d('Active wallet id: $walletId');
  final network = ref.watch(networkProvider);
  log.d('Network: $network');

  final maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);
  log.d('Max deposit claim fee: $maxDepositClaimFee');

  if (walletId == null) {
    log.e('No active wallet selected');
    throw Exception('No active wallet selected');
  }

  final storage = ref.read(walletStorageServiceProvider);
  final mnemonic = await storage.loadMnemonic(walletId);
  log.d('Mnemonic loaded: ${mnemonic != null}');

  if (mnemonic == null) {
    log.e('Wallet mnemonic not found');
    throw Exception('Wallet mnemonic not found');
  }

  final service = ref.read(breezSdkServiceProvider);
  log.d('Connecting BreezSdk for walletId: $walletId');
  final sdk = await service.connect(
    walletId: walletId,
    mnemonic: mnemonic,
    network: network,
    maxDepositClaimFee: maxDepositClaimFee,
  );
  log.d('BreezSdk connected');
  return sdk;
});

/// SDK event stream
final sdkEventsProvider = StreamProvider<SdkEvent>((ref) async* {
  log.d('sdkEventsProvider initializing');
  final sdk = await ref.watch(sdkProvider.future);
  await for (final event in sdk.addEventListener()) {
    log.d('SDK event received: ${event.runtimeType}');
    yield event;
  }
});

/// Node info - auto-refreshes on SDK events
final nodeInfoProvider = FutureProvider<GetInfoResponse>((ref) async {
  log.d('nodeInfoProvider initializing');
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);

  ref.listen(sdkEventsProvider, (_, _) {
    log.d('SDK event detected, invalidating nodeInfoProvider');
    ref.invalidateSelf();
  });

  final info = await service.getNodeInfo(sdk);
  log.d('Node info fetched: balanceSats=${info.balanceSats}');
  return info;
});

/// Balance derived from node info
final balanceProvider = Provider<AsyncValue<BigInt>>((ref) {
  log.d('balanceProvider initializing');
  return ref.watch(nodeInfoProvider).whenData((info) {
    log.d('Balance updated: ${info.balanceSats}');
    return info.balanceSats;
  });
});

/// Payments list - auto-refreshes on events
final paymentsProvider = FutureProvider<List<Payment>>((ref) async {
  log.d('paymentsProvider initializing');
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);

  ref.watch(nodeInfoProvider); // Refresh trigger

  final payments = await service.listPayments(sdk, ListPaymentsRequest());
  log.d('Payments fetched: count=${payments.length}');
  return payments;
});

/// Generate payment request
final receivePaymentProvider = FutureProvider.autoDispose
    .family<ReceivePaymentResponse, ReceivePaymentRequest>((ref, request) async {
      log.d('receivePaymentProvider called with request: $request');
      final sdk = await ref.watch(sdkProvider.future);
      final service = ref.read(breezSdkServiceProvider);
      final response = await service.receivePayment(sdk, request);
      log.d('Payment request generated: ${response.paymentRequest}');
      return response;
    });

/// Lightning address - with optional auto-registration
final lightningAddressProvider = FutureProvider.autoDispose.family<LightningAddressInfo?, bool>((
  ref,
  autoRegister,
) async {
  log.d('lightningAddressProvider called, autoRegister=$autoRegister');
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);

  // Don't auto-register if user manually deleted their address
  final manuallyDeleted = ref.watch(lightningAddressManuallyDeletedProvider);
  log.d('Lightning address manually deleted: $manuallyDeleted');
  final shouldAutoRegister = autoRegister && !manuallyDeleted;
  log.d('Should auto-register lightning address: $shouldAutoRegister');

  final info = await service.getLightningAddress(sdk, autoRegister: shouldAutoRegister);
  log.d('Lightning address info fetched: ${info?.lightningAddress}');
  return info;
});

/// Listen for SDK events (all events)
final sdkEventsStreamProvider = StreamProvider<SdkEvent>((ref) async* {
  log.d('sdkEventsStreamProvider initializing');
  final sdk = await ref.watch(sdkProvider.future);

  await for (final event in sdk.addEventListener()) {
    log.d('SDK event received: ${event.runtimeType}');

    // Handle events that need immediate provider invalidation
    event.when(
      synced: () {
        log.i('Wallet synced');
        ref.invalidate(nodeInfoProvider);
        ref.invalidate(paymentsProvider);
      },
      claimDepositsSucceeded: (claimedDeposits) {
        log.i('Deposits claimed successfully: ${claimedDeposits.length}');
        ref.invalidate(nodeInfoProvider);
        ref.invalidate(paymentsProvider);
      },
      claimDepositsFailed: (unclaimedDeposits) {
        log.e('Failed to claim ${unclaimedDeposits.length} deposits');
        for (final deposit in unclaimedDeposits) {
          log.e('Failed deposit: ${deposit.txid}:${deposit.vout}, error: ${deposit.claimError}');
        }
      },
      paymentSucceeded: (payment) {
        log.i('Payment succeeded: ${payment.id}');
        ref.invalidate(nodeInfoProvider);
        ref.invalidate(paymentsProvider);
      },
      paymentFailed: (payment) {
        log.e('Payment failed: ${payment.id}');
        ref.invalidate(paymentsProvider);
      },
    );

    yield event;
  }
});

/// Provider to list unclaimed deposits
final unclaimedDepositsProvider = FutureProvider<List<DepositInfo>>((ref) async {
  log.d('unclaimedDepositsProvider initializing');
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);

  // Watch the event stream to know when to refresh
  // This creates a dependency on the stream but doesn't create circular invalidation
  ref.watch(sdkEventsStreamProvider);

  final deposits = await service.listUnclaimedDeposits(sdk);
  log.d('Unclaimed deposits: ${deposits.length}');
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

  // Refresh UI
  ref.invalidate(nodeInfoProvider);
  ref.invalidate(paymentsProvider);
  ref.invalidate(unclaimedDepositsProvider);

  return response;
});
