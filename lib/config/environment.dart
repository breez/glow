/// App environment configuration
enum Environment {
  dev,
  prod;

  /// Get the current environment from compile-time constant
  static Environment get current {
    const String env = String.fromEnvironment('ENV', defaultValue: 'prod');
    return env.toLowerCase() == 'dev' ? Environment.dev : Environment.prod;
  }

  /// Get environment suffix for storage keys
  String get storageSuffix => switch (this) {
    Environment.dev => '_dev',
    Environment.prod => '',
  };

  /// Get application ID suffix
  String get appIdSuffix => switch (this) {
    Environment.dev => '.dev',
    Environment.prod => '',
  };

  /// Get display name for the environment
  String get displayName => switch (this) {
    Environment.dev => 'Development',
    Environment.prod => 'Production',
  };

  /// Check if this is a development build
  bool get isDev => this == Environment.dev;

  /// Check if this is a production build
  bool get isProd => this == Environment.prod;
}
