import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/core/services/breez_sdk_service.dart';
import 'package:glow/core/services/wallet_storage_service.dart';
import 'package:glow/features/developers/providers/max_deposit_fee_provider.dart';
import 'package:glow/features/developers/providers/network_provider.dart';

final log = AppLogger.getLogger('SdkProvider');

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

/// Node info - only updates when data actually changes
class NodeInfoNotifier extends AsyncNotifier<GetInfoResponse> {
  @override
  Future<GetInfoResponse> build() async {
    final sdk = await ref.watch(sdkProvider.future);
    final service = ref.read(breezSdkServiceProvider);
    return await service.getNodeInfo(sdk);
  }

  Future<void> refreshIfChanged() async {
    if (!state.hasValue) return;

    final sdk = await ref.read(sdkProvider.future);
    final service = ref.read(breezSdkServiceProvider);
    final newInfo = await service.getNodeInfo(sdk);

    // Only update if balance actually changed
    if (state.requireValue.balanceSats != newInfo.balanceSats) {
      log.d('Balance changed: ${state.requireValue.balanceSats} -> ${newInfo.balanceSats}');
      state = AsyncValue.data(newInfo);
    } else {
      log.t('Node info unchanged, skipping update');
    }
  }
}

final nodeInfoProvider = AsyncNotifierProvider<NodeInfoNotifier, GetInfoResponse>(() {
  return NodeInfoNotifier();
});

/// Payments list - only updates when payments actually change
class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() async {
    final sdk = await ref.watch(sdkProvider.future);
    final service = ref.read(breezSdkServiceProvider);
    final payments = await service.listPayments(sdk, ListPaymentsRequest());
    return payments;
  }

  Future<void> refreshIfChanged() async {
    if (!state.hasValue) return;

    final sdk = await ref.read(sdkProvider.future);
    final service = ref.read(breezSdkServiceProvider);
    final newPayments = await service.listPayments(sdk, ListPaymentsRequest());

    // Only update if payment list actually changed (compare by length and latest payment ID)
    final currentPayments = state.requireValue;
    final hasChanged =
        newPayments.length != currentPayments.length ||
        (newPayments.isNotEmpty &&
            currentPayments.isNotEmpty &&
            newPayments.first.id != currentPayments.first.id);

    if (hasChanged) {
      log.d('Payments changed: ${currentPayments.length} -> ${newPayments.length}');
      state = AsyncValue.data(newPayments);
    } else {
      log.t('Payments unchanged, skipping update');
    }
  }
}

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(PaymentsNotifier.new);

/// Balance - derived from node info, waits for payments to be loaded
final balanceProvider = Provider<AsyncValue<BigInt>>((ref) {
  // Ensure payments are loaded before showing balance
  // This prevents showing balance before transaction history is ready
  final payments = ref.watch(paymentsProvider);
  if (!payments.hasValue) {
    return const AsyncValue.loading();
  }

  final nodeInfo = ref.watch(nodeInfoProvider);
  return nodeInfo.when(
    data: (info) {
      log.t('Balance: ${info.balanceSats}');
      return AsyncValue.data(info.balanceSats);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Generate payment request
final receivePaymentProvider = FutureProvider.autoDispose
    .family<ReceivePaymentResponse, ReceivePaymentRequest>((ref, request) async {
      log.d('receivePaymentProvider called with request: ${request.paymentMethod}');
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
  final sdk = await ref.watch(sdkProvider.future);

  await for (final event in sdk.addEventListener()) {
    log.d('SDK event received: ${event.runtimeType}');
    yield event;
  }
});

/// Keep the SDK event stream alive and handle events
final sdkEventListenerProvider = Provider<void>((ref) {
  // Keep this provider alive
  ref.keepAlive();

  // Watch the stream and handle events
  ref.listen<AsyncValue<SdkEvent>>(sdkEventsStreamProvider, (previous, next) {
    next.whenData((event) async {
      // Handle events that need conditional provider updates
      event.when(
        synced: () async {
          log.i('Wallet synced');
        },
        dataSynced: (bool didPullNewRecords) async {
          log.i('Data synced');
          if (didPullNewRecords) {
            await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
            await ref.read(paymentsProvider.notifier).refreshIfChanged();
          }
        },
        paymentSucceeded: (payment) async {
          log.i('Payment succeeded: ${payment.id}');
          await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        paymentFailed: (payment) async {
          log.e('Payment failed: ${payment.id}');
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        unclaimedDeposits: (List<DepositInfo> unclaimedDeposits) {
          log.i('Unclaimed Deposits: ${unclaimedDeposits.length}');
        },
        claimedDeposits: (List<DepositInfo> claimedDeposits) {
          log.i('Claimed Deposits: ${claimedDeposits.length}');
        },
      );
    });
  });
});

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

// Track first sync state
class HasSyncedNotifier extends Notifier<bool> {
  @override
  bool build() {
    _initialize();
    return false;
  }

  Future<void> _initialize() async {
    log.d('HasSyncedNotifier: Waiting for SDK to connect...');
    await ref.read(sdkProvider.future);
    log.d('HasSyncedNotifier: SDK connected, now waiting for first sync...');

    ref.listen(sdkEventsStreamProvider, (previous, next) {
      (next as AsyncValue?)?.whenData((event) async {
        if (event is SdkEvent_Synced) {
          final wallet = ref.read(activeWalletProvider).value;
          if (wallet == null) return;

          final storage = ref.read(walletStorageServiceProvider);
          final alreadyMarked = await storage.hasCompletedFirstSync(wallet.id);

          if (!alreadyMarked) {
            await storage.markFirstSyncDone(wallet.id);
            log.d('First sync completed and marked for wallet: ${wallet.id}');
          } else {
            log.d('First sync completed after SDK connection for wallet: ${wallet.id}');
          }
          state = true;
        }
      });
    });
  }
}

final hasSyncedProvider = NotifierProvider<HasSyncedNotifier, bool>(() {
  return HasSyncedNotifier();
});

/// Whether to wait for initial sync before showing balance/payments
final shouldWaitForInitialSyncProvider = Provider<bool>((ref) {
  final wallet = ref.watch(activeWalletProvider).value;
  if (wallet == null) return false;

  final storage = ref.read(walletStorageServiceProvider);
  final future = storage.hasCompletedFirstSync(wallet.id);

  // Trigger async check but return false immediately
  future.then((synced) {
    if (synced) return;
    ref.invalidateSelf(); // refresh once result available
  });

  return false;
});
