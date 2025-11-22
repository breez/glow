import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';

final Logger log = AppLogger.getLogger('ShareService');

/// Provider for share service
final Provider<ShareService> shareServiceProvider = Provider<ShareService>((Ref ref) {
  return const ShareService();
});

class ShareService {
  const ShareService();

  /// Share text using the platform's share dialog
  Future<void> share({required String title, required String text}) async {
    log.i('Sharing content: $title');
    try {
      await SharePlus.instance.share(ShareParams(title: title, text: text));
      log.i('Share dialog opened successfully');
    } catch (e) {
      log.e('Failed to share content: $e');
    }
  }
}
