import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

/// Mixin that provides automatic logger with class name
///
/// Usage:
/// ```dart
/// class WalletScreen extends ConsumerWidget with LoggerMixin {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     log.i('Building wallet screen');  // Automatically uses 'WalletScreen' as context
///     return Scaffold(...);
///   }
/// }
/// ```
mixin LoggerMixin {
  Logger? _logger;

  /// Logger instance for this class
  /// Automatically uses the class name as context
  Logger get log {
    _logger ??= AppLogger.getLogger(runtimeType.toString());
    return _logger!;
  }
}
