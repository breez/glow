import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/services/breez_sdk_service.dart';
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
  final activeWallet = await ref.watch(activeWalletProvider.future);
  log.d('Active wallet: ${activeWallet?.id}');
  final network = ref.watch(networkProvider);
  log.d('Network: $network');

  if (activeWallet == null) {
    log.e('No active wallet selected');
    throw Exception('No active wallet selected');
  }

  final storage = ref.read(walletStorageServiceProvider);
  final mnemonic = await storage.loadMnemonic(activeWallet.id);
  log.d('Mnemonic loaded: ${mnemonic != null}');

  if (mnemonic == null) {
    log.e('Wallet mnemonic not found');
    throw Exception('Wallet mnemonic not found');
  }

  final service = ref.read(breezSdkServiceProvider);
  log.d('Connecting BreezSdk for walletId: ${activeWallet.id}');
  final sdk = await service.connect(walletId: activeWallet.id, mnemonic: mnemonic, network: network);
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

  ref.listen(sdkEventsProvider, (_, __) {
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
