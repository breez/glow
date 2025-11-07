import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/clipboard_service.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Reusable QR code card widget
class QRCodeCard extends ConsumerWidget {
  final String data;

  const QRCodeCard({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipboardService = ref.read(clipboardServiceProvider);
    return GestureDetector(
      onTap: () => clipboardService.copyToClipboard(context, data),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: PrettyQrView.data(
          data: data,
          decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Colors.black)),
        ),
      ),
    );
  }
}
