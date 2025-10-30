import 'dart:math' show Random;

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as breez_sdk_spark show connect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/config/breez_config.dart';
import 'package:glow/logging/breez_sdk_logger.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:path_provider/path_provider.dart';

/// SDK connection and lifecycle management
class BreezSdkService with LoggerMixin {
  /// Connect to Breez SDK with wallet-specific storage
  Future<BreezSdk> connect({
    required String walletId,
    required String mnemonic,
    required Network network,
    Fee? maxDepositClaimFee,
  }) async {
    log.i('Connecting SDK for wallet: $walletId on ${network.name}');

    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = '${appDir.path}/wallets/$walletId';

    final config = Config(
      apiKey: BreezConfig.apiKey,
      network: network,
      syncIntervalSecs: BreezConfig.defaultSyncIntervalSecs,
      maxDepositClaimFee: maxDepositClaimFee ?? BreezConfig.defaultMaxDepositClaimFee,
      lnurlDomain: BreezConfig.lnurlDomain,
      preferSparkOverLightning: true,
      useDefaultExternalInputParsers: false,
    );

    try {
      final sdk = await breez_sdk_spark.connect(
        request: ConnectRequest(
          config: config,
          seed: Seed.mnemonic(mnemonic: mnemonic),
          storageDir: storageDir,
        ),
      );

      log.i('SDK connected for wallet: $walletId');
      BreezSdkLogger.register(sdk);
      return sdk;
    } catch (e, stack) {
      log.e('Failed to connect SDK', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get node info (balance, tokens)
  Future<GetInfoResponse> getNodeInfo(BreezSdk sdk) async {
    return sdk.getInfo(request: GetInfoRequest());
  }

  /// List payments with filters
  Future<List<Payment>> listPayments(BreezSdk sdk, ListPaymentsRequest request) async {
    final response = await sdk.listPayments(request: request);
    return response.payments;
  }

  /// Generate payment request
  Future<ReceivePaymentResponse> receivePayment(BreezSdk sdk, ReceivePaymentRequest request) async {
    return sdk.receivePayment(request: request);
  }

  /// Get lightning address, with automatic registration if none exists
  Future<LightningAddressInfo?> getLightningAddress(BreezSdk sdk, {bool autoRegister = false}) async {
    final existing = await sdk.getLightningAddress();

    if (existing != null || !autoRegister) {
      return existing;
    }

    // Auto-register if none exists
    log.i('No Lightning Address found, attempting auto-registration');

    try {
      final registered = await _autoRegisterLightningAddress(sdk);
      if (registered) {
        return await sdk.getLightningAddress();
      }
    } catch (e, stack) {
      log.e('Auto-registration failed', error: e, stackTrace: stack);
    }

    return null;
  }

  /// Automatically register a Lightning Address with a base name and 4-digit suffix if needed
  Future<bool> _autoRegisterLightningAddress(BreezSdk sdk, {String baseName = 'glow'}) async {
    // First try the base name without suffix
    String username = baseName;
    bool available = await checkLightningAddressAvailable(sdk, username);

    if (available) {
      log.i('Registering Lightning Address: $username');
      await registerLightningAddress(sdk, username);
      return true;
    }

    // Try with 4-digit suffix (up to 10 attempts)
    final random = Random();
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      attempts++;
      // Generate 4-digit number (1000-9999)
      final suffix = random.nextInt(9000) + 1000;
      username = '$baseName$suffix';

      log.i('Checking availability for: $username (attempt $attempts)');
      available = await checkLightningAddressAvailable(sdk, username);

      if (available) {
        log.i('Registering Lightning Address: $username');
        await registerLightningAddress(sdk, username);
        return true;
      }
    }

    log.e('Failed to find available Lightning Address after $maxAttempts attempts');
    return false;
  }

  /// Check if a Lightning Address username is available
  Future<bool> checkLightningAddressAvailable(BreezSdk sdk, String username) async {
    try {
      return await sdk.checkLightningAddressAvailable(
        request: CheckLightningAddressRequest(username: username),
      );
    } catch (e, stack) {
      log.e('Failed to check Lightning Address availability', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Register a Lightning Address
  Future<void> registerLightningAddress(BreezSdk sdk, String username) async {
    try {
      await sdk.registerLightningAddress(request: RegisterLightningAddressRequest(username: username));
      log.i('Lightning Address registered: $username');
    } catch (e, stack) {
      log.e('Failed to register Lightning Address', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Delete Lightning Address
  Future<void> deleteLightningAddress(BreezSdk sdk) async {
    try {
      await sdk.deleteLightningAddress();
      log.i('Lightning Address deleted');
    } catch (e, stack) {
      log.e('Failed to delete Lightning Address', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Claim a pending deposit (for manual retry)
  Future<ClaimDepositResponse> claimDeposit(BreezSdk sdk, ClaimDepositRequest request) async {
    try {
      log.i('Manually claiming deposit: ${request.txid}:${request.vout}');
      final response = await sdk.claimDeposit(request: request);
      log.i('Deposit claimed successfully');
      return response;
    } catch (e, stack) {
      log.e('Failed to claim deposit', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// List unclaimed deposits
  Future<List<DepositInfo>> listUnclaimedDeposits(BreezSdk sdk) async {
    try {
      final response = await sdk.listUnclaimedDeposits(request: const ListUnclaimedDepositsRequest());
      if (response.deposits.isNotEmpty) {
        log.i('Found ${response.deposits.length} unclaimed deposits');
      }
      return response.deposits;
    } catch (e, stack) {
      log.e('Failed to list unclaimed deposits', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

final breezSdkServiceProvider = Provider((ref) => BreezSdkService());
