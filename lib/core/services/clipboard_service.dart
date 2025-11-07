import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/logging/app_logger.dart';

final log = AppLogger.getLogger('ClipboardService');

/// Provider for clipboard service
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  return ClipboardService();
});

class ClipboardService {
  const ClipboardService();

  Future<String?> getClipboardText() async {
    log.i('Attempting to fetch clipboard data');
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;
      if (text == null || text.isEmpty) {
        log.w('Clipboard is empty');
      } else {
        log.i('Clipboard data fetched: ${text.length} characters');
      }
      return text;
    } catch (e) {
      log.e('Failed to fetch clipboard data: $e');
      return null;
    }
  }

  /// Copy text to clipboard and show a snackbar notification
  void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    log.i('Copied text to clipboard: ${text.length} characters');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)));
  }
}
