import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' show Fee;

/// App-specific configuration for Breez SDK connection.
class BreezConfig {
  static const apiKey = String.fromEnvironment('BREEZ_API_KEY');
  static const defaultSyncIntervalSecs = 60;
  static const lnurlDomain = "breez.tips";
  static Fee get defaultMaxDepositClaimFee => Fee.rate(satPerVbyte: BigInt.from(1));
}
