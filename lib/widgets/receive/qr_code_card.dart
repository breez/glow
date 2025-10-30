import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Reusable QR code card widget
class QRCodeCard extends StatelessWidget {
  final String data;

  const QRCodeCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: PrettyQrView.data(
        data: data,
        decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Colors.black)),
      ),
    );
  }
}
