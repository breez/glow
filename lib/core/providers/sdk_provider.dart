import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/core/services/breez_sdk_service.dart';
import 'package:glow/core/services/wallet_storage_service.dart';
import 'package:glow/features/developers/providers/max_deposit_fee_provider.dart';
import 'package:glow/features/developers/providers/network_provider.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('SdkProvider');

/// Track if Lightning Address was manually deleted (to prevent auto-registration)
class LightningAddressManuallyDeletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    log.d('LightningAddressManuallyDeletedNotifier initialized');
    // Reset when wallet changes
    ref.listen(activeWalletProvider, (
      AsyncValue<WalletMetadata?>? previous,
      AsyncValue<WalletMetadata?> next,
    ) {
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

final NotifierProvider<LightningAddressManuallyDeletedNotifier, bool>
lightningAddressManuallyDeletedProvider = NotifierProvider<LightningAddressManuallyDeletedNotifier, bool>(
  LightningAddressManuallyDeletedNotifier.new,
);

/// Connected SDK instance - auto-reconnects on wallet/network changes
final FutureProvider<BreezSdk> sdkProvider = FutureProvider<BreezSdk>((Ref ref) async {
  final String? walletId = ref.watch(activeWalletIdProvider);
  log.d('Active wallet id: $walletId');
  final Network network = ref.watch(networkProvider);
  log.d('Network: $network');

  final Fee maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);
  log.d('Max deposit claim fee: $maxDepositClaimFee');

  if (walletId == null) {
    log.e('No active wallet selected');
    throw Exception('No active wallet selected');
  }

  final WalletStorageService storage = ref.read(walletStorageServiceProvider);
  final String? mnemonic = await storage.loadMnemonic(walletId);
  log.d('Mnemonic loaded: ${mnemonic != null}');

  if (mnemonic == null) {
    log.e('Wallet mnemonic not found');
    throw Exception('Wallet mnemonic not found');
  }

  final BreezSdkService service = ref.read(breezSdkServiceProvider);
  return await service.connect(
    walletId: walletId,
    mnemonic: mnemonic,
    network: network,
    maxDepositClaimFee: maxDepositClaimFee,
  );
});

/// Node info - only updates when data actually changes
class NodeInfoNotifier extends AsyncNotifier<GetInfoResponse> {
  @override
  Future<GetInfoResponse> build() async {
    final BreezSdk sdk = await ref.watch(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    return await service.getNodeInfo(sdk);
  }

  Future<void> refreshIfChanged() async {
    if (!state.hasValue) {
      return;
    }

    final BreezSdk sdk = await ref.read(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    final GetInfoResponse newInfo = await service.getNodeInfo(sdk);

    // Only update if balance actually changed
    if (state.requireValue.balanceSats != newInfo.balanceSats) {
      log.d('Balance changed: ${state.requireValue.balanceSats} -> ${newInfo.balanceSats}');
      state = AsyncValue<GetInfoResponse>.data(newInfo);
    } else {
      log.t('Node info unchanged, skipping update');
    }
  }
}

final AsyncNotifierProvider<NodeInfoNotifier, GetInfoResponse> nodeInfoProvider =
    AsyncNotifierProvider<NodeInfoNotifier, GetInfoResponse>(() {
      return NodeInfoNotifier();
    });

/// Payments list - only updates when payments actually change
class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() async {
    final BreezSdk sdk = await ref.watch(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    final List<Payment> payments = await service.listPayments(sdk, const ListPaymentsRequest());
    return payments;
  }

  Future<void> refreshIfChanged() async {
    if (!state.hasValue) {
      return;
    }

    final BreezSdk sdk = await ref.read(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    final List<Payment> newPayments = await service.listPayments(sdk, const ListPaymentsRequest());

    // Only update if payment list actually changed (compare by length and latest payment ID)
    final List<Payment> currentPayments = state.requireValue;
    final bool hasChanged =
        newPayments.length != currentPayments.length ||
        (newPayments.isNotEmpty &&
            currentPayments.isNotEmpty &&
            newPayments.first.id != currentPayments.first.id);

    if (hasChanged) {
      log.d('Payments changed: ${currentPayments.length} -> ${newPayments.length}');
      state = AsyncValue<List<Payment>>.data(newPayments);
    } else {
      log.t('Payments unchanged, skipping update');
    }
  }
}

final AsyncNotifierProvider<PaymentsNotifier, List<Payment>> paymentsProvider =
    AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(PaymentsNotifier.new);

/// Balance - derived from node info, waits for payments to be loaded
final Provider<AsyncValue<BigInt>> balanceProvider = Provider<AsyncValue<BigInt>>((Ref ref) {
  // Ensure payments are loaded before showing balance
  // This prevents showing balance before transaction history is ready
  final AsyncValue<List<Payment>> payments = ref.watch(paymentsProvider);
  if (!payments.hasValue) {
    return const AsyncValue<BigInt>.loading();
  }

  final AsyncValue<GetInfoResponse> nodeInfo = ref.watch(nodeInfoProvider);
  return nodeInfo.when(
    data: (GetInfoResponse info) {
      log.t('Balance: ${info.balanceSats}');
      return AsyncValue<BigInt>.data(info.balanceSats);
    },
    loading: () => const AsyncValue<BigInt>.loading(),
    error: (Object error, StackTrace stack) => AsyncValue<BigInt>.error(error, stack),
  );
});

/// Generate payment request
final FutureProviderFamily<ReceivePaymentResponse, ReceivePaymentRequest> receivePaymentProvider =
    FutureProvider.autoDispose.family<ReceivePaymentResponse, ReceivePaymentRequest>((
      Ref ref,
      ReceivePaymentRequest request,
    ) async {
      log.d('receivePaymentProvider called with request: ${request.paymentMethod}');
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);
      final ReceivePaymentResponse response = await service.receivePayment(sdk, request);
      log.d('Payment request generated: ${response.paymentRequest}');
      return response;
    });

/// Lightning address - with optional auto-registration
final FutureProviderFamily<LightningAddressInfo?, bool> lightningAddressProvider = FutureProvider.autoDispose
    .family<LightningAddressInfo?, bool>((Ref ref, bool autoRegister) async {
      log.d('lightningAddressProvider called, autoRegister=$autoRegister');
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);

      // Don't auto-register if user manually deleted their address
      final bool manuallyDeleted = ref.watch(lightningAddressManuallyDeletedProvider);
      log.d('Lightning address manually deleted: $manuallyDeleted');
      final bool shouldAutoRegister = autoRegister && !manuallyDeleted;
      log.d('Should auto-register lightning address: $shouldAutoRegister');

      final LightningAddressInfo? info = await service.getLightningAddress(
        sdk,
        autoRegister: shouldAutoRegister,
      );
      log.d('Lightning address info fetched: ${info?.lightningAddress}');
      return info;
    });

/// Listen for SDK events (all events)
final StreamProvider<SdkEvent> sdkEventsStreamProvider = StreamProvider<SdkEvent>((Ref ref) async* {
  final BreezSdk sdk = await ref.watch(sdkProvider.future);

  await for (final SdkEvent event in sdk.addEventListener()) {
    log.d('SDK event received: ${event.runtimeType}');
    yield event;
  }
});

/// Keep the SDK event stream alive and handle events
final Provider<void> sdkEventListenerProvider = Provider<void>((Ref ref) {
  // Keep this provider alive
  ref.keepAlive();

  // Watch the stream and handle events
  ref.listen<AsyncValue<SdkEvent>>(sdkEventsStreamProvider, (
    AsyncValue<SdkEvent>? previous,
    AsyncValue<SdkEvent> next,
  ) {
    next.whenData((SdkEvent event) async {
      // Handle events that need conditional provider updates
      event.when(
        synced: () async {
          log.i('Wallet synced');
          await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        dataSynced: (bool didPullNewRecords) async {
          log.i('Data synced');
          if (didPullNewRecords) {
            await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
            await ref.read(paymentsProvider.notifier).refreshIfChanged();
          }
        },
        paymentSucceeded: (Payment payment) async {
          log.i('Payment succeeded: ${payment.id}');
          await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        paymentPending: (Payment payment) async {
          log.i('Payment pending: ${payment.id}');
          await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        paymentFailed: (Payment payment) async {
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
      final Fee maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);

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

    ref.listen(sdkEventsStreamProvider, (AsyncValue<SdkEvent>? previous, AsyncValue<SdkEvent> next) {
      (next as AsyncValue<SdkEvent>?)?.whenData((SdkEvent event) async {
        if (event is SdkEvent_Synced) {
          final WalletMetadata? wallet = ref.read(activeWalletProvider).value;
          if (wallet == null) {
            return;
          }

          final WalletStorageService storage = ref.read(walletStorageServiceProvider);
          final bool alreadyMarked = await storage.hasCompletedFirstSync(wallet.id);

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

final NotifierProvider<HasSyncedNotifier, bool> hasSyncedProvider = NotifierProvider<HasSyncedNotifier, bool>(
  () {
    return HasSyncedNotifier();
  },
);

/// Whether to wait for initial sync before showing balance/payments
final Provider<bool> shouldWaitForInitialSyncProvider = Provider<bool>((Ref ref) {
  final WalletMetadata? wallet = ref.watch(activeWalletProvider).value;
  if (wallet == null) {
    return false;
  }

  final WalletStorageService storage = ref.read(walletStorageServiceProvider);
  final Future<bool> future = storage.hasCompletedFirstSync(wallet.id);

  // Trigger async check but return false immediately
  future.then((bool synced) {
    if (synced) {
      return;
    }
    ref.invalidateSelf(); // refresh once result available
  });

  return false;
});
