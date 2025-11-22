import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('QrScanService');

/// Provider for QR scan service
final Provider<QrScanService> qrScanServiceProvider = Provider<QrScanService>((Ref ref) {
  return const QrScanService();
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
