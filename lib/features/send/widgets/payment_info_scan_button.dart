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
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: themeData.colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(Icons.qr_code_scanner, size: 20.0, color: themeData.colorScheme.primary),
        label: AutoSizeText(
          'SCAN',
          style: themeData.textTheme.labelLarge,
          maxLines: 1,
          group: textGroup,
          stepGranularity: 0.1,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
