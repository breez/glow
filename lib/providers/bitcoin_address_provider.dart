import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';

final log = AppLogger.getLogger('BitcoinAddressProvider');

/// Provider for getting the current Bitcoin address
/// Uses receivePayment with BitcoinAddress method (no amount)
/// The SDK returns the cached static deposit address or generates a new one
final bitcoinAddressProvider = FutureProvider.autoDispose<BitcoinAddressData?>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);

  try {
    log.d('Fetching Bitcoin address from SDK');

    // Call receivePayment with BitcoinAddress method
    // SDK will return cached address or generate new one
    final response = await sdk.receivePayment(
      request: const ReceivePaymentRequest(paymentMethod: ReceivePaymentMethod.bitcoinAddress()),
    );

    // The paymentRequest is just the Bitcoin address string
    final address = response.paymentRequest;
    log.d('Received Bitcoin address: $address');

    // Parse the address to get network details
    final input = await sdk.parse(input: address);

    return input.maybeWhen(
      bitcoinAddress: (details) {
        log.d('Successfully parsed Bitcoin address: ${details.address}, network: ${details.network}');
        return BitcoinAddressData(address: details.address, network: details.network, source: details.source);
      },
      orElse: () {
        // Fallback: create data without parsing
        // Assume mainnet if we can't parse
        log.w('Failed to parse Bitcoin address, using fallback detection');
        return BitcoinAddressData(
          address: address,
          network: _detectNetworkFromAddress(address),
          source: PaymentRequestSource(),
        );
      },
    );
  } catch (e) {
    // Log error but return null instead of throwing
    // This allows the UI to handle the absence gracefully
    log.e('Error fetching Bitcoin address: $e');
    return null;
  }
});

/// Provider for generating a new Bitcoin address
/// Note: According to the SDK code, it caches the first address
/// So calling this multiple times may return the same cached address
/// The SDK logic:
/// 1. Check storage cache
/// 2. Check existing addresses (list_static_deposit_addresses)
/// 3. Only generates new if no addresses exist
final generateBitcoinAddressProvider = FutureProvider.autoDispose.family<BitcoinAddressData?, void>((
  ref,
  _,
) async {
  final sdk = await ref.watch(sdkProvider.future);

  try {
    log.d('Generating new Bitcoin address');

    // Call receivePayment again
    // Per SDK code, this will return cached address if it exists
    final response = await sdk.receivePayment(
      request: const ReceivePaymentRequest(paymentMethod: ReceivePaymentMethod.bitcoinAddress()),
    );

    final address = response.paymentRequest;
    log.d('Generated Bitcoin address: $address');

    final input = await sdk.parse(input: address);

    final addressData = input.maybeWhen(
      bitcoinAddress: (details) {
        log.d('Parsed generated address: ${details.address}, network: ${details.network}');

        return BitcoinAddressData(address: details.address, network: details.network, source: details.source);
      },
      orElse: () {
        log.w('Failed to parse generated address, using fallback');
        return BitcoinAddressData(
          address: address,
          network: _detectNetworkFromAddress(address),
          source: PaymentRequestSource(),
        );
      },
    );

    // Invalidate the main provider to refresh UI
    ref.invalidate(bitcoinAddressProvider);
    log.d('Invalidated bitcoinAddressProvider for UI refresh');

    return addressData;
  } catch (e) {
    log.e('Error generating Bitcoin address: $e');
    return null;
  }
});

/// Provider for Bitcoin address with amount (BIP21 URI)
/// Currently, the SDK has TODO for supporting amount in BitcoinAddress method
/// So we get the base address and create the BIP21 URI manually
final bitcoinAddressWithAmountProvider = FutureProvider.autoDispose.family<BitcoinBip21Data?, BigInt>((
  ref,
  amountSats,
) async {
  log.d('Creating BIP21 URI with amount: $amountSats sats');

  // First get the base address
  final addressData = await ref.watch(bitcoinAddressProvider.future);

  if (addressData == null) {
    log.w('No Bitcoin address available for BIP21 URI creation');
    return null;
  }

  // Create BIP21 URI with amount
  final bip21Uri = _createBip21Uri(
    address: addressData.address,
    amountSats: amountSats,
    label: 'Payment',
    message: null,
  );

  log.d('Created BIP21 URI: $bip21Uri');

  return BitcoinBip21Data(
    address: addressData.address,
    network: addressData.network,
    amountSats: amountSats,
    bip21Uri: bip21Uri,
  );
});

/// Provider for creating BIP21 URI from parameters
/// This is a synchronous provider since we're just building a string
final bip21UriProvider = Provider.family<String, Bip21UriParams>((ref, params) {
  return _createBip21Uri(
    address: params.address,
    amountSats: params.amountSats,
    label: params.label,
    message: params.message,
  );
});

/// Helper: Create BIP21 URI
/// Format: bitcoin:ADDRESS?amount=0.00000000&label=LABEL&message=MESSAGE
String _createBip21Uri({required String address, BigInt? amountSats, String? label, String? message}) {
  final buffer = StringBuffer('bitcoin:$address');
  final queryParams = <String>[];

  if (amountSats != null && amountSats > BigInt.zero) {
    // Convert sats to BTC (8 decimal places)
    final btc = amountSats.toDouble() / 100000000;
    queryParams.add('amount=${btc.toStringAsFixed(8)}');
  }

  if (label != null && label.isNotEmpty) {
    queryParams.add('label=${Uri.encodeComponent(label)}');
  }

  if (message != null && message.isNotEmpty) {
    queryParams.add('message=${Uri.encodeComponent(message)}');
  }

  if (queryParams.isNotEmpty) {
    buffer.write('?${queryParams.join('&')}');
  }

  return buffer.toString();
}

/// Helper: Detect network from address format
/// This is used as fallback if SDK parse fails
BitcoinNetwork _detectNetworkFromAddress(String address) {
  // Mainnet patterns
  if (address.startsWith('bc1') || // Bech32
      address.startsWith('1') || // P2PKH
      address.startsWith('3')) {
    // P2SH
    return BitcoinNetwork.bitcoin;
  }

  // Testnet patterns
  if (address.startsWith('tb1') || // Testnet Bech32
      address.startsWith('m') || // Testnet P2PKH
      address.startsWith('n') || // Testnet P2PKH
      address.startsWith('2')) {
    // Testnet P2SH
    return BitcoinNetwork.testnet3;
  }

  // Signet pattern
  if (address.startsWith('sb1')) {
    return BitcoinNetwork.signet;
  }

  // Regtest pattern
  if (address.startsWith('bcrt1')) {
    return BitcoinNetwork.regtest;
  }

  // Default to mainnet
  return BitcoinNetwork.bitcoin;
}

/// Data class for Bitcoin address
/// Represents a parsed Bitcoin address with network information
class BitcoinAddressData {
  final String address;
  final BitcoinNetwork network;
  final PaymentRequestSource source;

  const BitcoinAddressData({required this.address, required this.network, required this.source});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BitcoinAddressData &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          network == other.network &&
          source == other.source;

  @override
  int get hashCode => address.hashCode ^ network.hashCode ^ source.hashCode;

  @override
  String toString() => 'BitcoinAddressData(address: $address, network: $network)';
}

/// Data class for Bitcoin BIP21 URI with amount
/// Includes both the base address and the formatted BIP21 URI
class BitcoinBip21Data {
  final String address;
  final BitcoinNetwork network;
  final BigInt amountSats;
  final String bip21Uri;

  const BitcoinBip21Data({
    required this.address,
    required this.network,
    required this.amountSats,
    required this.bip21Uri,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BitcoinBip21Data &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          network == other.network &&
          amountSats == other.amountSats &&
          bip21Uri == other.bip21Uri;

  @override
  int get hashCode => address.hashCode ^ network.hashCode ^ amountSats.hashCode ^ bip21Uri.hashCode;

  @override
  String toString() => 'BitcoinBip21Data(address: $address, amount: $amountSats sats)';
}

/// Parameters for creating a BIP21 URI
/// Used with bip21UriProvider
class Bip21UriParams {
  final String address;
  final BigInt? amountSats;
  final String? label;
  final String? message;

  const Bip21UriParams({required this.address, this.amountSats, this.label, this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bip21UriParams &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          amountSats == other.amountSats &&
          label == other.label &&
          message == other.message;

  @override
  int get hashCode => address.hashCode ^ amountSats.hashCode ^ label.hashCode ^ message.hashCode;

  @override
  String toString() => 'Bip21UriParams(address: $address, amount: $amountSats)';
}
