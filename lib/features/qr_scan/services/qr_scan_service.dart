import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:glow/routing/app_routes.dart';

final log = AppLogger.getLogger('QrScanService');

/// Provider for QR scan service
final qrScanServiceProvider = Provider<QrScanService>((ref) {
  return QrScanService();
});

class QrScanService {
  const QrScanService();

  Future<String?> scanQrCode(BuildContext context) async {
    log.i('Opening QR scanner');
    final String? barcode = await Navigator.pushNamed<String>(context, AppRoutes.qrScan);
    if (barcode == null) {
      log.i('QR scan cancelled');
      return null;
    }
    if (barcode.isEmpty) {
      log.w('Empty QR code scanned');
      return null;
    }
    log.i('QR code scanned: ${barcode.substring(0, barcode.length > 50 ? 50 : barcode.length)}...');
    return barcode;
  }
}
