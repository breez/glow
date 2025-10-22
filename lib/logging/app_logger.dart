import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Central logging system with file output and session management
class AppLogger {
  static AppLogger? _instance;
  static File? _logFile;
  static final _fileOutput = _FileOutput();

  Stream<LogEntry>? _sdkLogStream;

  AppLogger._();

  /// Initialize logging system once at app startup
  static Future<void> initialize() async {
    if (_instance != null) return;

    _instance = AppLogger._();

    // Create log file for this session
    _logFile = await _createSessionLogFile();
    _fileOutput.setFile(_logFile!);

    // Log session start with device info
    final log = getLogger('AppLogger');
    await _logSessionStart(log);

    // Cleanup old logs
    await _cleanupOldLogs(log);
  }

  /// Create a logger for a specific class/file
  ///
  /// Usage: `final log = AppLogger.getLogger('WalletScreen');`
  static Logger getLogger(String name) {
    if (_instance == null) {
      throw StateError('AppLogger not initialized. Call AppLogger.initialize() first');
    }

    return Logger(printer: _CustomPrinter(name), output: _fileOutput);
  }

  /// Register SDK log listener
  static void registerBreezSdkLog(BreezSdk breezSdk) {
    if (_instance == null) return;

    final sdkLog = getLogger('BreezSDK');

    // Only initialize the log stream if it hasn't been created yet
    // This prevents calling initLogging() multiple times on hot restart
    if (_instance!._sdkLogStream == null) {
      try {
        _instance!._sdkLogStream = initLogging().asBroadcastStream();
        _instance!._sdkLogStream!.listen((entry) => _logSdkEntry(entry, sdkLog));
        getLogger('AppLogger').i('Registered Breez SDK log listener');
      } catch (e) {
        // If initLogging() was already called (e.g., after hot restart),
        // log the error but don't crash the app
        getLogger('AppLogger').w('Failed to register SDK log listener (already initialized): $e');
      }
    } else {
      getLogger('AppLogger').d('SDK log listener already registered, skipping');
    }
  }

  /// Creates a new log file for this session
  static Future<File> _createSessionLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${dir.path}/logs');

    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'session_$timestamp.log';
    final file = File('${logsDir.path}/$fileName');

    await file.writeAsString('=== Session Started: ${DateTime.now()} ===\n\n');
    return file;
  }

  /// Logs device information at session start
  static Future<void> _logSessionStart(Logger log) async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        log.i('Android Device: ${info.model} (${info.manufacturer})');
        log.i('Android Version: ${info.version.release} (SDK ${info.version.sdkInt})');
        log.i('Device ID: ${info.id}');
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        log.i('iOS Device: ${info.model} (${info.name})');
        log.i('iOS Version: ${info.systemVersion}');
        log.i('Device ID: ${info.identifierForVendor}');
      }
    } catch (e, stack) {
      log.e('Failed to get device info', error: e, stackTrace: stack);
    }
  }

  /// Keeps only the last 10 session logs
  static Future<void> _cleanupOldLogs(Logger log) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/logs');

      if (!await logsDir.exists()) return;

      final files = logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).toList();

      // Sort by modified date (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Delete all except last 10
      if (files.length > 10) {
        for (var i = 10; i < files.length; i++) {
          await files[i].delete();
          log.d('Deleted old log: ${files[i].path.split('/').last}');
        }
      }
    } catch (e, stack) {
      log.e('Failed to cleanup old logs', error: e, stackTrace: stack);
    }
  }

  /// Log SDK entries according to their severity
  static void _logSdkEntry(LogEntry entry, Logger log) {
    switch (entry.level) {
      case 'ERROR':
        log.e(entry.line);
        break;
      case 'WARN':
        log.w(entry.line);
        break;
      case 'INFO':
        log.i(entry.line);
        break;
      case 'DEBUG':
        log.d(entry.line);
        break;
      case 'TRACE':
        log.t(entry.line);
        break;
      default:
        log.i(entry.line);
    }
  }

  /// Get path to current log file (for sharing/debugging)
  static String? get currentLogPath => _logFile?.path;

  /// Get directory containing all log files
  static Future<Directory> get logsDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/logs');
  }

  /// Share current session log file
  /// Returns the file path for sharing via share_plus or similar
  static Future<File?> getCurrentSessionLog() async {
    return _logFile;
  }

  /// Create a zip file of all session logs
  /// Returns the zip file path for sharing
  static Future<File?> createAllLogsZip() async {
    final log = getLogger('AppLogger');

    try {
      log.i('Creating zip of all logs...');
      final logsDir = await logsDirectory;

      if (!await logsDir.exists()) {
        log.w('Logs directory does not exist');
        return null;
      }

      final logFiles = logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).toList();

      if (logFiles.isEmpty) {
        log.w('No log files to zip');
        return null;
      }

      // Create archive
      final archive = Archive();
      for (final file in logFiles) {
        final fileName = file.path.split('/').last;
        final bytes = await file.readAsBytes();
        log.d('Adding $fileName (${bytes.length} bytes) to archive');
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }

      // Encode to zip
      final zipData = ZipEncoder().encode(archive);

      // Write to temp directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final zipFile = File('${tempDir.path}/glow_logs_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      log.i('Created zip: ${zipFile.path}, size: ${zipData.length} bytes');
      return zipFile;
    } catch (e, stack) {
      log.e('Failed to create logs zip', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Create a zip file of the current session log only
  /// Returns the zip file path for sharing
  static Future<File?> createCurrentSessionZip() async {
    final log = getLogger('AppLogger');

    if (_logFile == null) {
      log.w('No current log file');
      return null;
    }

    try {
      log.i('Creating zip of current session log...');

      final fileName = _logFile!.path.split('/').last;
      final bytes = await _logFile!.readAsBytes();

      // Create archive with single file
      final archive = Archive();
      archive.addFile(ArchiveFile(fileName, bytes.length, bytes));

      // Encode to zip
      final zipData = ZipEncoder().encode(archive);

      // Write to temp directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final zipFile = File('${tempDir.path}/glow_session_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      log.i('Created session zip: ${zipFile.path}, size: ${zipData.length} bytes');
      return zipFile;
    } catch (e, stack) {
      log.e('Failed to create session zip', error: e, stackTrace: stack);
      return null;
    }
  }
}

/// Custom printer that includes class/file name for context
class _CustomPrinter extends LogPrinter {
  final String className;

  _CustomPrinter(this.className);

  @override
  List<String> log(LogEvent event) {
    final time = DateTime.now().toString().split(' ')[1].split('.')[0];
    final levelEmoji = _getLevelEmoji(event.level);
    final levelName = event.level.toString().split('.').last.toUpperCase();

    final message = event.message;
    final error = event.error != null ? '\n${event.error}' : '';
    final stack = event.stackTrace != null ? '\n${event.stackTrace}' : '';

    return ['$time $levelEmoji [$className] $levelName: $message$error$stack'];
  }

  String _getLevelEmoji(Level level) {
    switch (level) {
      case Level.trace:
        return '🔍';
      case Level.debug:
        return '🐛';
      case Level.info:
        return '💡';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '⛔';
      case Level.fatal:
        return '💀';
      default:
        return '📝';
    }
  }
}

/// Custom output that writes to both console and file
class _FileOutput extends LogOutput {
  File? _file;

  void setFile(File file) {
    _file = file;
  }

  @override
  void output(OutputEvent event) {
    // Write to console
    for (var line in event.lines) {
      if (kDebugMode) {
        print(line);
      }
    }

    // Write to file (async, fire and forget)
    if (_file != null) {
      _writeToFile(event.lines);
    }
  }

  Future<void> _writeToFile(List<String> lines) async {
    if (_file == null) return;

    try {
      // Strip ANSI color codes for file output
      final cleanLines = lines.map((line) => _stripAnsi(line));
      final content = '${cleanLines.join('\n')}\n';
      await _file!.writeAsString(content, mode: FileMode.append);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to write log to file: $e');
      }
    }
  }

  String _stripAnsi(String text) {
    final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
    return text.replaceAll(ansiRegex, '');
  }
}
