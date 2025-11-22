import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/services/clipboard_service.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Reusable QR code card widget
class QRCodeCard extends ConsumerWidget {
  final String data;

  const QRCodeCard({required this.data, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ClipboardService clipboardService = ref.read(clipboardServiceProvider);
    return GestureDetector(
      onTap: () => clipboardService.copyToClipboard(context, data),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          width: 230.0,
          height: 230.0,
          clipBehavior: Clip.antiAlias,
          decoration: const ShapeDecoration(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
          child: PrettyQrView.data(
            data: data,
            decoration: const PrettyQrDecoration(
              quietZone: PrettyQrQuietZone.modules(1),
              background: Colors.white,
              shape: PrettyQrSquaresSymbol(),
            ),
          ),
        ),
      ),
    );
  }
}
