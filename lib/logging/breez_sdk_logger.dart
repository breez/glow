import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

/// Bridges Breez SDK logs to AppLogger
class BreezSdkLogger {
  static BreezSdkLogger? _instance;
  Stream<LogEntry>? _logStream;

  BreezSdkLogger._();

  /// Register SDK log listener (idempotent, safe for hot reload)
  static void register(BreezSdk breezSdk) {
    _instance ??= BreezSdkLogger._();

    if (_instance!._logStream != null) {
      AppLogger.getLogger('BreezSdkLogger').d('Already registered');
      return;
    }

    final Logger log = AppLogger.getLogger('BreezSDK');

    try {
      _instance!._logStream = initLogging().asBroadcastStream();
      _instance!._logStream!.listen((LogEntry entry) => _logEntry(entry, log));
      AppLogger.getLogger('BreezSdkLogger').i('Registered SDK log listener');
    } catch (e) {
      AppLogger.getLogger('BreezSdkLogger').w('Already initialized: $e');
    }
  }

  static void _logEntry(LogEntry entry, Logger log) {
    final void Function(dynamic message, {Object? error, StackTrace? stackTrace, DateTime? time}) logFn =
        switch (entry.level) {
          'ERROR' => log.e,
          'WARN' => log.w,
          'INFO' => log.i,
          'DEBUG' => log.d,
          'TRACE' => log.t,
          _ => log.i,
        };
    logFn(entry.line);
  }
}
