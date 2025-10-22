import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:glow_breez/providers/wallet_provider.dart';
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

const _kApiKey = 'your_api_key_here';
const _kLnAddress = 'your_ln_address';
const _kLnAddressUsername = 'your_ln_address_username';

final _log = AppLogger.getLogger('SdkProvider');

/// Current selected network
///
/// `NotifierProvider` - For mutable state with methods
/// `Notifier<T>` - Base class for stateful logic, T is the state type
class NetworkNotifier extends Notifier<Network> {
  final _log = AppLogger.getLogger('NetworkNotifier');

  @override
  Network build() => Network.mainnet;

  void setNetwork(Network network) {
    _log.i('Network changed: ${network.name}');
    state = network; // Updates state and notifies listeners
  }
}

final networkProvider = NotifierProvider<NetworkNotifier, Network>(NetworkNotifier.new);

/// REMOVED: Old hardcoded mnemonic notifier
/// Now using wallet system with activeWalletProvider and activeWalletMnemonicProvider
/// from wallet_provider.dart for proper multi-wallet support

// ============================================================================
// Core SDK
// ============================================================================

/// Connected Breez SDK instance
///
/// MULTI-WALLET SUPPORT:
/// - Watches activeWalletProvider for wallet changes
/// - Automatically disconnects and reconnects when wallet switches
/// - Each wallet has isolated storage directory: {appDir}/wallets/{wallet_id}/
/// - Uses mnemonic from activeWalletMnemonicProvider
///
/// SDK LIFECYCLE:
/// 1. App start → Load active wallet → connect()
/// 2. Wallet switch → disconnect() → Load new wallet → connect()
/// 3. Network change → disconnect() → connect() (same wallet, new network)
///
/// `FutureProvider` - For async operations that complete once
/// Automatically caches the result, only reconnects when dependencies change
final sdkProvider = FutureProvider<BreezSdk>((ref) async {
  _log.i('Initializing Breez SDK...');

  // Watch for wallet and network changes - causes automatic reconnection
  final activeWallet = await ref.watch(activeWalletProvider.future);
  final network = ref.watch(networkProvider);

  // Early return if no active wallet
  if (activeWallet == null) {
    _log.w('No active wallet - SDK not connected');
    throw Exception('No active wallet selected');
  }

  _log.i('Connecting SDK for wallet: ${activeWallet.id} (${activeWallet.name}) on ${network.name}');

  // Get mnemonic for active wallet
  final storage = ref.read(walletStorageServiceProvider);
  final mnemonic = await storage.loadMnemonic(activeWallet.id);

  if (mnemonic == null) {
    _log.e('Mnemonic not found for wallet: ${activeWallet.id}');
    throw Exception('Wallet mnemonic not found');
  }

  final config = Config(
    apiKey: _kApiKey,
    network: network,
    syncIntervalSecs: 60,
    preferSparkOverLightning: true,
  );

  // CRITICAL: Each wallet gets isolated storage directory
  // This prevents wallet data from mixing
  final appDir = await getApplicationDocumentsDirectory();
  final walletStorageDir = '${appDir.path}/wallets/${activeWallet.id}';
  _log.d('Wallet storage directory: $walletStorageDir');

  try {
    _log.i('Connecting to Breez SDK...');
    var breezSdk = await connect(
      request: ConnectRequest(
        config: config,
        seed: Seed.mnemonic(mnemonic: mnemonic),
        storageDir: walletStorageDir,
      ),
    );

    _log.i('Successfully connected to Breez SDK for wallet: ${activeWallet.id}');
    AppLogger.registerBreezSdkLog(breezSdk);

    return breezSdk;
  } catch (e, stack) {
    _log.e('Failed to connect to Breez SDK', error: e, stackTrace: stack);
    rethrow;
  }
});

// ============================================================================
// Events
// ============================================================================

/// Stream of all SDK events
///
/// `StreamProvider` - For continuous data streams
/// Yields events as they arrive, widgets rebuild on each new event
final sdkEventsProvider = StreamProvider<SdkEvent>((ref) async* {
  final log = AppLogger.getLogger('SdkEvents');
  final sdk = await ref.watch(sdkProvider.future);
  log.i('Started listening to SDK events');

  await for (final event in sdk.addEventListener()) {
    log.t('Event: ${event.runtimeType}');
    yield event;
  }
});

/// Stream of successful payments
final paymentSuccessEventsProvider = StreamProvider<Payment>((ref) async* {
  final log = AppLogger.getLogger('PaymentSuccessEvents');
  final sdk = await ref.watch(sdkProvider.future);

  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_PaymentSucceeded) {
      log.i('Payment succeeded: ${event.payment.id}, amount: ${event.payment.amount}');
      yield event.payment;
    }
  }
});

/// Stream of failed payments
final paymentFailedEventsProvider = StreamProvider<Payment>((ref) async* {
  final log = AppLogger.getLogger('PaymentFailedEvents');
  final sdk = await ref.watch(sdkProvider.future);

  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_PaymentFailed) {
      log.w('Payment failed: ${event.payment.id}');
      yield event.payment;
    }
  }
});

/// Stream of claim deposit success events
final claimDepositsSuccessEventsProvider = StreamProvider<List<DepositInfo>>((ref) async* {
  final log = AppLogger.getLogger('ClaimDepositsEvents');
  final sdk = await ref.watch(sdkProvider.future);

  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_ClaimDepositsSucceeded) {
      log.i('Deposits claimed: ${event.claimedDeposits.length}');
      yield event.claimedDeposits;
    }
  }
});

/// Stream of sync events
final syncEventsProvider = StreamProvider<void>((ref) async* {
  final log = AppLogger.getLogger('SyncEvents');
  final sdk = await ref.watch(sdkProvider.future);

  await for (final event in sdk.addEventListener()) {
    if (event is SdkEvent_Synced) {
      log.i('Wallet synced');
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
  final log = AppLogger.getLogger('NodeInfo');
  final sdk = await ref.watch(sdkProvider.future);

  /* TODO(erdemyerebasmaz): Invalidate on payment success or sync (updates balance and payment metadata)
   after debugging why balance & payment list did not update for certain payments
   */
  // Listen to SDK events and invalidate when they occur
  ref.listen(sdkEventsProvider, (_, event) {
    if (event.hasValue) {
      log.d('SDK event received, invalidating node info');
      ref.invalidateSelf(); // Triggers refetch
    }
  });

  try {
    log.d('Fetching node info...');
    final info = await sdk.getInfo(request: GetInfoRequest());
    log.i('Node info: balance=${info.balanceSats} sats, tokens=${info.tokenBalances.length}');
    return info;
  } catch (e, stack) {
    log.e('Failed to get node info', error: e, stackTrace: stack);
    rethrow;
  }
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
  final log = AppLogger.getLogger('Payments');
  final sdk = await ref.watch(sdkProvider.future);
  // Refresh on payment success events
  ref.watch(paymentSuccessEventsProvider);

  log.d('Fetching payments with filters...');
  final response = await sdk.listPayments(request: request);
  log.i('Fetched ${response.payments.length} payments');
  return response.payments;
});

/// Get all payments (no filters)
final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final log = AppLogger.getLogger('AllPayments');
  final sdk = await ref.watch(sdkProvider.future);

  // Refresh whenever node info refreshes
  ref.watch(nodeInfoProvider);

  try {
    log.d('Fetching all payments...');
    final response = await sdk.listPayments(request: ListPaymentsRequest());
    log.i('Fetched ${response.payments.length} total payments');
    return response.payments;
  } catch (e, stack) {
    log.e('Failed to fetch payments', error: e, stackTrace: stack);
    rethrow;
  }
});

/// Get single payment by ID
final paymentProvider = FutureProvider.autoDispose.family<Payment, String>((ref, paymentId) async {
  final log = AppLogger.getLogger('Payment');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Fetching payment: $paymentId');
  final response = await sdk.getPayment(request: GetPaymentRequest(paymentId: paymentId));
  log.i('Payment fetched: ${response.payment.amount} sats');
  return response.payment;
});

// ============================================================================
// Send Payment
// ============================================================================

/// Prepare send payment (calculates fees, validates)
final prepareSendPaymentProvider = FutureProvider.autoDispose
    .family<PrepareSendPaymentResponse, PrepareSendPaymentRequest>((ref, request) async {
      final log = AppLogger.getLogger('PrepareSendPayment');
      final sdk = await ref.watch(sdkProvider.future);

      log.i('Preparing send payment...');
      try {
        final response = await sdk.prepareSendPayment(request: request);
        log.i('Send payment prepared: amount=${response.amount} sats');
        return response;
      } catch (e, stack) {
        log.e('Failed to prepare send payment', error: e, stackTrace: stack);
        rethrow;
      }
    });

/// Send payment
final sendPaymentProvider = FutureProvider.autoDispose.family<Payment, SendPaymentRequest>((
  ref,
  request,
) async {
  final log = AppLogger.getLogger('SendPayment');
  final sdk = await ref.watch(sdkProvider.future);

  log.i('Sending payment...');
  try {
    final response = await sdk.sendPayment(request: request);
    log.i('Payment sent successfully: ${response.payment.id}');
    return response.payment;
  } catch (e, stack) {
    log.e('Failed to send payment', error: e, stackTrace: stack);
    rethrow;
  }
});

// ============================================================================
// Receive Payment
// ============================================================================

/// Generate payment request (invoice, address, etc)
final receivePaymentProvider = FutureProvider.autoDispose
    .family<ReceivePaymentResponse, ReceivePaymentRequest>((ref, request) async {
      final log = AppLogger.getLogger('ReceivePayment');
      final sdk = await ref.watch(sdkProvider.future);

      log.i('Generating payment request...');
      try {
        final response = await sdk.receivePayment(request: request);
        log.i('Payment request generated, fee: ${response.feeSats} sats');
        return response;
      } catch (e, stack) {
        log.e('Failed to generate payment request', error: e, stackTrace: stack);
        rethrow;
      }
    });

/// Wait for a payment to complete
final waitForPaymentProvider = FutureProvider.autoDispose.family<Payment, WaitForPaymentRequest>((
  ref,
  request,
) async {
  final log = AppLogger.getLogger('WaitForPayment');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Waiting for payment...');
  final response = await sdk.waitForPayment(request: request);
  log.i('Payment completed: ${response.payment.id}');
  return response.payment;
});

// ============================================================================
// LNURL
// ============================================================================

/// Prepare LNURL pay
final prepareLnurlPayProvider = FutureProvider.autoDispose
    .family<PrepareLnurlPayResponse, PrepareLnurlPayRequest>((ref, request) async {
      final log = AppLogger.getLogger('PrepareLnurlPay');
      final sdk = await ref.watch(sdkProvider.future);

      log.i('Preparing LNURL pay...');
      final response = await sdk.prepareLnurlPay(request: request);
      log.i('LNURL pay prepared: ${response.amountSats} sats');
      return response;
    });

/// Execute LNURL pay
final lnurlPayProvider = FutureProvider.autoDispose.family<LnurlPayResponse, LnurlPayRequest>((
  ref,
  request,
) async {
  final log = AppLogger.getLogger('LnurlPay');
  final sdk = await ref.watch(sdkProvider.future);

  log.i('Executing LNURL pay...');
  final response = await sdk.lnurlPay(request: request);
  log.i('LNURL pay completed');
  return response;
});

// ============================================================================
// Lightning Address
// ============================================================================

/// Check if lightning address username is available
final checkLightningAddressProvider = FutureProvider.autoDispose.family<bool, String>((ref, username) async {
  final log = AppLogger.getLogger('CheckLightningAddress');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Checking Lightning Address availability: $username');
  final available = await sdk.checkLightningAddressAvailable(
    request: CheckLightningAddressRequest(username: username),
  );
  log.i('Lightning Address "$username" available: $available');
  return available;
});

/// Register lightning address
final registerLightningAddressProvider = FutureProvider.autoDispose
    .family<LightningAddressInfo, RegisterLightningAddressRequest>((ref, request) async {
      final log = AppLogger.getLogger('RegisterLightningAddress');
      final sdk = await ref.watch(sdkProvider.future);

      log.i('Registering Lightning Address: ${request.username}');
      final info = await sdk.registerLightningAddress(request: request);
      log.i('Lightning Address registered: ${info.lightningAddress}');
      return info;
    });

/// Get current lightning address
final lightningAddressProvider = FutureProvider<LightningAddressInfo?>((ref) async {
  final log = AppLogger.getLogger('LightningAddress');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Fetching Lightning Address...');
  final address = await sdk.getLightningAddress();

  if (address != null) {
    log.i('Lightning Address: ${address.lightningAddress}');
  } else {
    log.w('No Lightning Address found, using fallback');
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
  final log = AppLogger.getLogger('UnclaimedDeposits');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Fetching unclaimed deposits...');
  final response = await sdk.listUnclaimedDeposits(request: ListUnclaimedDepositsRequest());
  log.i('Found ${response.deposits.length} unclaimed deposits');
  return response.deposits;
});

/// Claim a deposit
final claimDepositProvider = FutureProvider.autoDispose.family<Payment, ClaimDepositRequest>((
  ref,
  request,
) async {
  final log = AppLogger.getLogger('ClaimDeposit');
  final sdk = await ref.watch(sdkProvider.future);

  log.i('Claiming deposit: ${request.txid}:${request.vout}');
  final response = await sdk.claimDeposit(request: request);
  log.i('Deposit claimed successfully');
  return response.payment;
});

/// Refund a deposit
final refundDepositProvider = FutureProvider.autoDispose.family<RefundDepositResponse, RefundDepositRequest>((
  ref,
  request,
) async {
  final log = AppLogger.getLogger('RefundDeposit');
  final sdk = await ref.watch(sdkProvider.future);

  log.i('Refunding deposit: ${request.txid}:${request.vout}');
  final response = await sdk.refundDeposit(request: request);
  log.i('Deposit refunded: ${response.txId}');
  return response;
});

// ============================================================================
// Tokens
// ============================================================================

/// Get metadata for tokens
final tokensMetadataProvider = FutureProvider.autoDispose.family<List<TokenMetadata>, List<String>>((
  ref,
  tokenIdentifiers,
) async {
  final log = AppLogger.getLogger('TokensMetadata');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Fetching metadata for ${tokenIdentifiers.length} tokens');
  final response = await sdk.getTokensMetadata(
    request: GetTokensMetadataRequest(tokenIdentifiers: tokenIdentifiers),
  );
  log.i('Token metadata fetched: ${response.tokensMetadata.length} tokens');
  return response.tokensMetadata;
});

// ============================================================================
// Fiat Rates
// ============================================================================

/// List all supported fiat currencies
final fiatCurrenciesProvider = FutureProvider<List<FiatCurrency>>((ref) async {
  final log = AppLogger.getLogger('FiatCurrencies');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Fetching fiat currencies...');
  final response = await sdk.listFiatCurrencies();
  log.i('Fetched ${response.currencies.length} fiat currencies');
  return response.currencies;
});

/// Get current fiat exchange rates
final fiatRatesProvider = FutureProvider<List<Rate>>((ref) async {
  final log = AppLogger.getLogger('FiatRates');
  final sdk = await ref.watch(sdkProvider.future);

  log.d('Fetching fiat rates...');
  final response = await sdk.listFiatRates();
  log.i('Fetched ${response.rates.length} fiat rates');
  return response.rates;
});

// ============================================================================
// Utilities
// ============================================================================

/// Parse payment string (invoice, address, LNURL, etc)
final parseInputProvider = FutureProvider.autoDispose.family<InputType, String>((ref, input) async {
  final log = AppLogger.getLogger('ParseInput');
  log.d('Parsing input: ${input.substring(0, 20)}...');

  final result = await parse(input: input);
  log.i('Parsed as: ${result.runtimeType}');
  return result;
});

/// Sync wallet
final syncWalletProvider = FutureProvider.autoDispose<void>((ref) async {
  final log = AppLogger.getLogger('SyncWallet');
  final sdk = await ref.watch(sdkProvider.future);

  log.i('Manually syncing wallet...');
  await sdk.syncWallet(request: SyncWalletRequest());
  log.i('Wallet sync completed');
});
