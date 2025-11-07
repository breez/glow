import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/qr_scan/services/qr_scan_service.dart';
import 'package:glow/routing/input_handlers.dart';
import 'package:glow/core/logging/app_logger.dart';

final log = AppLogger.getLogger('QrScanButton');

class QrScanButton extends ConsumerWidget {
  const QrScanButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: FloatingActionButton(onPressed: () => _scanBarcode(context, ref), child: Icon(Icons.qr_code)),
    );
  }

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final qrScanService = ref.read(qrScanServiceProvider);
    final String? barcode = await qrScanService.scanQrCode(context);
    if (barcode == null) {
      return;
    }

    if (barcode.isEmpty && context.mounted) {
      final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('No QR code found in image')));
      return;
    }

    // Use input handler to parse and navigate
    if (context.mounted) {
      final inputHandler = ref.read(inputHandlerProvider);
      await inputHandler.handleInput(context, barcode);
    }
  }
}
