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
  }) async {
    log.i('Connecting SDK for wallet: $walletId on ${network.name}');

    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = '${appDir.path}/wallets/$walletId';

    final config = Config(
      apiKey: BreezConfig.apiKey,
      network: network,
      syncIntervalSecs: BreezConfig.syncIntervalSecs,
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

  /// Get lightning address
  Future<LightningAddressInfo?> getLightningAddress(BreezSdk sdk) async {
    return await sdk.getLightningAddress();
  }
}

final breezSdkServiceProvider = Provider((ref) => BreezSdkService());
