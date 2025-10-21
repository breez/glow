import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ============================================================================
// Riverpod State Management Overview
// ============================================================================
//
// Key Concepts:
//
// 1. Provider Types:
//    - FutureProvider: For async operations that complete once (e.g., API calls)
//    - StreamProvider: For continuous data streams (e.g., real-time events)
//    - Provider: For synchronous, derived state (e.g., transforming data)
//    - NotifierProvider: For mutable state with methods (e.g., settings)
//
// 2. Modifiers:
//    - .autoDispose: Auto-cleanup when no widgets watch it (prevents memory leaks)
//    - .family: Accept parameters to create unique provider instances
//
// 3. Watching vs Reading:
//    - ref.watch(): Subscribe to changes, rebuilds widget when data changes
//    - ref.read(): One-time read, doesn't subscribe (use for callbacks/events)
//    - ref.listen(): React to changes without rebuilding (side effects)
//
//    Side effects = Actions triggered by state changes that don't update UI directly
//    Examples: showing notifications, logging, invalidating other providers, payment arrives -> invalidate balance
//
// 4. Usage Patterns:
//    - Watch in build(): ref.watch(balanceProvider)
//    - Read in callbacks: ref.read(sendPaymentProvider(...).future)
//    - Listen for side effects: ref.listen(eventProvider, (prev, next) { })
//
// ============================================================================

// ============================================================================
// Configuration
// ============================================================================

const _kMnemonic = 'your twelve word mnemonic phrase goes here for testing purposes only';
const _kApiKey = 'your_api_key_here';
const _kLnAddress = 'your_ln_address';
const _kLnAddressUsername = 'your_ln_address_username';

/// Current selected network
///
/// `NotifierProvider` - For mutable state with methods
/// `Notifier<T>` - Base class for stateful logic, T is the state type
class NetworkNotifier extends Notifier<Network> {
  @override
  Network build() => Network.mainnet;

  void setNetwork(Network network) {
    state = network; // Updates state and notifies listeners
  }
}

final networkProvider = NotifierProvider<NetworkNotifier, Network>(NetworkNotifier.new);

// ============================================================================
// Core SDK
// ============================================================================

/// Connected Breez SDK instance
///
/// `FutureProvider` - For async operations that complete once
/// Automatically caches the result, only reconnects when dependencies change
final sdkProvider = FutureProvider<BreezSdk>((ref) async {
  // Reconnect on network changes
  final network = ref.watch(networkProvider);

  final config = Config(
    apiKey: _kApiKey,
    network: network,
    syncIntervalSecs: 60,
    preferSparkOverLightning: true,
  );

  final directory = await getApplicationDocumentsDirectory();

  return await connect(
    request: ConnectRequest(
      config: config,
      seed: Seed.mnemonic(mnemonic: _kMnemonic),
      storageDir: directory.path,
    ),
  );
});

// ============================================================================
// Events
// ============================================================================

/// Stream of all SDK events
///
/// `StreamProvider` - For continuous data streams
/// Yields events as they arrive, widgets rebuild on each new event
final sdkEventsProvider = StreamProvider<SdkEvent>((ref) async* {
  final sdk = await ref.watch(sdkProvider.future);
  await for (final event in sdk.addEventListener()) {
    yield event;
  }
});

/// Stream of successful payments
final paymentSuccessEventsProvider = StreamProvider<Payment>((ref) async* {
  final sdk = await ref.watch(sdkProvider.future);
  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_PaymentSucceeded) {
      yield event.payment;
    }
  }
});

/// Stream of failed payments
final paymentFailedEventsProvider = StreamProvider<Payment>((ref) async* {
  final sdk = await ref.watch(sdkProvider.future);
  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_PaymentFailed) {
      yield event.payment;
    }
  }
});

/// Stream of claim deposit success events
final claimDepositsSuccessEventsProvider = StreamProvider<List<DepositInfo>>((ref) async* {
  final sdk = await ref.watch(sdkProvider.future);
  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_ClaimDepositsSucceeded) {
      yield event.claimedDeposits;
    }
  }
});

/// Stream of sync events
final syncEventsProvider = StreamProvider<void>((ref) async* {
  final sdk = await ref.watch(sdkProvider.future);
  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_Synced) {
      yield null;
    }
  }
});

// ============================================================================
// Node Info & Balance
// ============================================================================

/// Node information (balance, tokens)
///
/// `ref.listen()` - Reacts to changes without rebuilding
/// `ref.invalidateSelf()` - Forces provider to refetch data
final nodeInfoProvider = FutureProvider<GetInfoResponse>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);

  /* TODO(erdemyerebasmaz): Invalidate on payment success or sync (updates balance and payment metadata)
   after debugging why balance & payment list did not update for certain payments
   */
  // Listen to SDK events and invalidate when they occur
  ref.listen(sdkEventsProvider, (_, _) {
    ref.invalidateSelf(); // Triggers refetch
  });

  return sdk.getInfo(request: GetInfoRequest());
});

/// Bitcoin balance in sats
///
/// `Provider` - For synchronous, derived state
/// Transforms data from another provider without async operations
final balanceProvider = Provider<AsyncValue<BigInt>>((ref) {
  final nodeInfo = ref.watch(nodeInfoProvider);
  return nodeInfo.whenData((info) => info.balanceSats); // Extracts balance from node info
});

/// Token balances
final tokenBalancesProvider = Provider<AsyncValue<Map<String, TokenBalance>>>((ref) {
  final nodeInfo = ref.watch(nodeInfoProvider);
  return nodeInfo.whenData((info) => info.tokenBalances);
});

// ============================================================================
// Payments
// ============================================================================

/// List all payments with optional filters
///
/// `.autoDispose` - Provider automatically cleans up when no longer used
/// `.family` - Takes a parameter (request) to create unique provider instances
final paymentsProvider = FutureProvider.autoDispose.family<List<Payment>, ListPaymentsRequest>((
  ref,
  request,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  // Refresh on payment success events
  ref.watch(paymentSuccessEventsProvider);
  final response = await sdk.listPayments(request: request);
  return response.payments;
});

/// Get all payments (no filters)
final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);

  // Refresh whenever node info refreshes
  ref.watch(nodeInfoProvider);

  final response = await sdk.listPayments(request: ListPaymentsRequest());
  return response.payments;
});

/// Get single payment by ID
final paymentProvider = FutureProvider.autoDispose.family<Payment, String>((ref, paymentId) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.getPayment(request: GetPaymentRequest(paymentId: paymentId));
  return response.payment;
});

// ============================================================================
// Send Payment
// ============================================================================

/// Prepare send payment (calculates fees, validates)
///
/// Usage:
/// ```dart
/// final prepareSendPaymentResponse = await ref.read(
///   prepareSendPaymentProvider(
///     PrepareSendPaymentRequest(paymentRequest: invoice),
///   ).future,
/// );
/// ```
final prepareSendPaymentProvider = FutureProvider.autoDispose
    .family<PrepareSendPaymentResponse, PrepareSendPaymentRequest>((ref, request) async {
      final sdk = await ref.watch(sdkProvider.future);
      return sdk.prepareSendPayment(request: request);
    });

/// Send payment
final sendPaymentProvider = FutureProvider.autoDispose.family<Payment, SendPaymentRequest>((
  ref,
  request,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.sendPayment(request: request);
  return response.payment;
});

// ============================================================================
// Receive Payment
// ============================================================================

/// Generate payment request (invoice, address, etc)
final receivePaymentProvider = FutureProvider.autoDispose
    .family<ReceivePaymentResponse, ReceivePaymentRequest>((ref, request) async {
      final sdk = await ref.watch(sdkProvider.future);
      return sdk.receivePayment(request: request);
    });

/// Wait for a payment to complete
final waitForPaymentProvider = FutureProvider.autoDispose.family<Payment, WaitForPaymentRequest>((
  ref,
  request,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.waitForPayment(request: request);
  return response.payment;
});

// ============================================================================
// LNURL
// ============================================================================

/// Prepare LNURL pay
final prepareLnurlPayProvider = FutureProvider.autoDispose
    .family<PrepareLnurlPayResponse, PrepareLnurlPayRequest>((ref, request) async {
      final sdk = await ref.watch(sdkProvider.future);
      return sdk.prepareLnurlPay(request: request);
    });

/// Execute LNURL pay
final lnurlPayProvider = FutureProvider.autoDispose.family<LnurlPayResponse, LnurlPayRequest>((
  ref,
  request,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  return sdk.lnurlPay(request: request);
});

// ============================================================================
// Lightning Address
// ============================================================================

/// Check if lightning address username is available
final checkLightningAddressProvider = FutureProvider.autoDispose.family<bool, String>((ref, username) async {
  final sdk = await ref.watch(sdkProvider.future);
  return sdk.checkLightningAddressAvailable(request: CheckLightningAddressRequest(username: username));
});

/// Register lightning address
final registerLightningAddressProvider = FutureProvider.autoDispose
    .family<LightningAddressInfo, RegisterLightningAddressRequest>((ref, request) async {
      final sdk = await ref.watch(sdkProvider.future);
      return sdk.registerLightningAddress(request: request);
    });

/// Get current lightning address
final lightningAddressProvider = FutureProvider<LightningAddressInfo?>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final address = await sdk.getLightningAddress();
  if (kDebugMode) {
    print('Lightning Address from SDK: ${address?.lightningAddress}');
  }

  // TODO(erdemyerebasmaz): Remove hardcoded value after investigating why LN address from SDK is empty
  // Fallback to hardcoded address if SDK returns null
  if (address == null) {
    return LightningAddressInfo(
      lightningAddress: _kLnAddress,
      lnurl: '',
      username: _kLnAddressUsername,
      description: '',
    );
  }

  return address;
});

// ============================================================================
// Deposits
// ============================================================================

/// List unclaimed deposits
final unclaimedDepositsProvider = FutureProvider<List<DepositInfo>>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.listUnclaimedDeposits(request: ListUnclaimedDepositsRequest());
  return response.deposits;
});

/// Claim a deposit
final claimDepositProvider = FutureProvider.autoDispose.family<Payment, ClaimDepositRequest>((
  ref,
  request,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.claimDeposit(request: request);
  return response.payment;
});

/// Refund a deposit
final refundDepositProvider = FutureProvider.autoDispose.family<RefundDepositResponse, RefundDepositRequest>((
  ref,
  request,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  return sdk.refundDeposit(request: request);
});

// ============================================================================
// Tokens
// ============================================================================

/// Get metadata for tokens
final tokensMetadataProvider = FutureProvider.autoDispose.family<List<TokenMetadata>, List<String>>((
  ref,
  tokenIdentifiers,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.getTokensMetadata(
    request: GetTokensMetadataRequest(tokenIdentifiers: tokenIdentifiers),
  );
  return response.tokensMetadata;
});

// ============================================================================
// Fiat Rates
// ============================================================================

/// List all supported fiat currencies
final fiatCurrenciesProvider = FutureProvider<List<FiatCurrency>>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.listFiatCurrencies();
  return response.currencies;
});

/// Get current fiat exchange rates
final fiatRatesProvider = FutureProvider<List<Rate>>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final response = await sdk.listFiatRates();
  return response.rates;
});

// ============================================================================
// Utilities
// ============================================================================

/// Parse payment string (invoice, address, LNURL, etc)
final parseInputProvider = FutureProvider.autoDispose.family<InputType, String>((ref, input) async {
  return parse(input: input);
});

/// Sync wallet
final syncWalletProvider = FutureProvider.autoDispose<void>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  await sdk.syncWallet(request: SyncWalletRequest());
});
