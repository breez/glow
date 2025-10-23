import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/providers/wallet_provider.dart';
import 'package:glow_breez/services/breez_sdk_service.dart';
import 'package:glow_breez/services/wallet_storage_service.dart';

/// Network selection state
class NetworkNotifier extends Notifier<Network> {
  @override
  Network build() => Network.mainnet;

  void setNetwork(Network network) => state = network;
}

final networkProvider = NotifierProvider<NetworkNotifier, Network>(NetworkNotifier.new);

/// Connected SDK instance - auto-reconnects on wallet/network changes
final sdkProvider = FutureProvider<BreezSdk>((ref) async {
  final activeWallet = await ref.watch(activeWalletProvider.future);
  final network = ref.watch(networkProvider);

  if (activeWallet == null) {
    throw Exception('No active wallet selected');
  }

  final storage = ref.read(walletStorageServiceProvider);
  final mnemonic = await storage.loadMnemonic(activeWallet.id);

  if (mnemonic == null) {
    throw Exception('Wallet mnemonic not found');
  }

  final service = ref.read(breezSdkServiceProvider);
  return service.connect(walletId: activeWallet.id, mnemonic: mnemonic, network: network);
});

/// SDK event stream
final sdkEventsProvider = StreamProvider<SdkEvent>((ref) async* {
  final sdk = await ref.watch(sdkProvider.future);
  await for (final event in sdk.addEventListener()) {
    yield event;
  }
});

/// Node info - auto-refreshes on SDK events
final nodeInfoProvider = FutureProvider<GetInfoResponse>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);

  ref.listen(sdkEventsProvider, (_, _) => ref.invalidateSelf());

  return service.getNodeInfo(sdk);
});

/// Balance derived from node info
final balanceProvider = Provider<AsyncValue<BigInt>>((ref) {
  return ref.watch(nodeInfoProvider).whenData((info) => info.balanceSats);
});

/// Payments list - auto-refreshes on events
final paymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);

  ref.watch(nodeInfoProvider); // Refresh trigger

  return service.listPayments(sdk, ListPaymentsRequest());
});

/// Generate payment request
final receivePaymentProvider = FutureProvider.autoDispose
    .family<ReceivePaymentResponse, ReceivePaymentRequest>((ref, request) async {
      final sdk = await ref.watch(sdkProvider.future);
      final service = ref.read(breezSdkServiceProvider);
      return service.receivePayment(sdk, request);
    });

/// Lightning address
final lightningAddressProvider = FutureProvider<LightningAddressInfo?>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final service = ref.read(breezSdkServiceProvider);
  return service.getLightningAddress(sdk);
});
