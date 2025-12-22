import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' show MaxFee;

/// App-specific configuration for Breez SDK connection.
class BreezConfig {
  static const String apiKey = String.fromEnvironment('BREEZ_API_KEY');
  static const int defaultSyncIntervalSecs = 60;
  static const String lnurlDomain = 'breez.cash';
  static MaxFee get defaultMaxDepositClaimFee => MaxFee.rate(satPerVbyte: BigInt.from(1));
}
