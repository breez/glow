import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/routing/app_routes.dart';
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
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final inputHandler = ref.read(inputHandlerProvider);

    log.i('Start QR code scan');

    final String? barcode = await Navigator.pushNamed<String>(context, AppRoutes.qrScan);

    log.i("Scanned string: '$barcode'");

    if (barcode == null) {
      log.i('Scan cancelled by user');
      return;
    }

    if (barcode.isEmpty && context.mounted) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('No QR code found in image')));
      return;
    }

    // Use input handler to parse and navigate
    if (context.mounted) {
      await inputHandler.handleInput(context, barcode);
    }
  }
}
