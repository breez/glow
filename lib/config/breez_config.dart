/// App-specific configuration for Breez SDK connection.
class BreezConfig {
  static const apiKey = String.fromEnvironment('BREEZ_API_KEY');
  static const syncIntervalSecs = 60;
}
