import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A button that allows scanning QR codes
class PaymentInfoScanButton extends StatelessWidget {
  final VoidCallback onPressed;
  final AutoSizeGroup? textGroup;

  const PaymentInfoScanButton({required this.onPressed, this.textGroup, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 138.0),
      child: Tooltip(
        message: 'Scan Invoice or Lightning Address',
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
          ),
          icon: Icon(Icons.qr_code, size: 24.0, color: themeData.colorScheme.primary),
          label: AutoSizeText(
            'SCAN',
            style: const TextStyle(
              fontSize: 16,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
              height: 1.24,
            ),
            maxLines: 1,
            group: textGroup,
            stepGranularity: 0.1,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
