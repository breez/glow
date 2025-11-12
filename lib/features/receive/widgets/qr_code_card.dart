import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/clipboard_service.dart';
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: PrettyQrView.data(data: data, decoration: const PrettyQrDecoration()),
      ),
    );
  }
}
