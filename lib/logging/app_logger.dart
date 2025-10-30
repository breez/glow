import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Session-based logging system with ZIP archival utilities.
///
/// - Writes logs to per-session files.
/// - Can archive current or all session logs.
/// - Automatically manages old logs.
class AppLogger {
  static AppLogger? _instance;
  static File? _logFile;
  static final _fileOutput = _FileOutput();

  AppLogger._();

  static Future<void> initialize() async {
    if (_instance != null) return;
    _instance = AppLogger._();

    _logFile = await _createSessionLogFile();
    _fileOutput.setFile(_logFile!);

    final log = getLogger('AppLogger');
    await _logSessionStart(log);
    await _cleanupOldLogs(log);
  }

  static Logger getLogger(String name) {
    if (_instance == null) {
      throw StateError('AppLogger not initialized. Call AppLogger.initialize() first');
    }
    return Logger(
      filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
      printer: _CustomPrinter(name),
      output: _fileOutput,
      level: kDebugMode ? Level.debug : Level.info,
    );
  }

  static Future<File> _createSessionLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${dir.path}/logs');
    await logsDir.create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final file = File('${logsDir.path}/session_$timestamp.log');
    await file.writeAsString('=== Session Started: ${DateTime.now()} ===\n\n');
    return file;
  }

  static Future<void> _logSessionStart(Logger log) async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        log.i('Android ${info.model} (${info.manufacturer}), SDK ${info.version.sdkInt}');
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        log.i('iOS ${info.model} (${info.name}), ${info.systemVersion}');
      }
    } catch (e, stack) {
      log.e('Failed to get device info', error: e, stackTrace: stack);
    }
  }

  static Future<void> _cleanupOldLogs(Logger log) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/logs');
      if (!await logsDir.exists()) return;

      final files = logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      for (var i = 10; i < files.length; i++) {
        await files[i].delete();
      }
    } catch (e, stack) {
      log.e('Failed to cleanup old logs', error: e, stackTrace: stack);
    }
  }

  static Future<Directory> get logsDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/logs');
  }

  static Future<File?> createAllLogsZip() async {
    final log = getLogger('AppLogger');
    try {
      final logsDir = await logsDirectory;
      if (!await logsDir.exists()) return null;

      final logFiles = logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).toList();

      if (logFiles.isEmpty) return null;

      final archive = Archive();
      for (final file in logFiles) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(file.path.split('/').last, bytes.length, bytes));
      }

      final zipData = ZipEncoder().encode(archive);
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final zipFile = File('${tempDir.path}/glow_logs_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      log.i('Created zip: ${zipFile.path}');
      return zipFile;
    } catch (e, stack) {
      log.e('Failed to create logs zip', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<File?> createCurrentSessionZip() async {
    if (_logFile == null) return null;

    try {
      final bytes = await _logFile!.readAsBytes();
      final archive = Archive()..addFile(ArchiveFile(_logFile!.path.split('/').last, bytes.length, bytes));

      final zipData = ZipEncoder().encode(archive);
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final zipFile = File('${tempDir.path}/glow_session_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      return zipFile;
    } catch (_) {
      return null;
    }
  }
}

class _CustomPrinter extends LogPrinter {
  final String className;
  static const _classWidth = 22;
  static const _levelWidth = 9;

  _CustomPrinter(this.className);

  @override
  List<String> log(LogEvent e) {
    final time = e.time.toUtc().toIso8601String();
    final source = '[$className]'.padRight(_classWidth);
    final level = '{${e.level.name.toUpperCase()}}'.padLeft(_levelWidth);

    final b = StringBuffer('$time $source $level: ${e.message}');
    if (e.error != null) b.writeln(e.error);
    if (e.stackTrace != null) b.writeln(e.stackTrace);
    return [b.toString()];
  }
}

class _FileOutput extends LogOutput {
  File? _file;

  void setFile(File file) => _file = file;

  @override
  void output(OutputEvent event) {
    if (kDebugMode) {
      for (var line in event.lines) {
        print(line);
      }
    }
    if (_file != null) _writeToFile(event.lines);
  }

  Future<void> _writeToFile(List<String> lines) async {
    if (_file == null) return;
    try {
      final cleanLines = lines.map(_stripAnsi);
      await _file!.writeAsString('${cleanLines.join('\n')}\n', mode: FileMode.append);
    } catch (_) {}
  }

  String _stripAnsi(String text) => text.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
}
