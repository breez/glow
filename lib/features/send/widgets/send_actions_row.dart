import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/send/widgets/payment_info_paste_button.dart';
import 'package:glow/features/send/widgets/payment_info_scan_button.dart';

class SendActionsRow extends StatelessWidget {
  final VoidCallback onPaste;
  final VoidCallback onScan;
  final AutoSizeGroup textGroup;

  const SendActionsRow({super.key, required this.onPaste, required this.onScan, required this.textGroup});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PaymentInfoPasteButton(onPressed: onPaste, textGroup: textGroup),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PaymentInfoScanButton(onPressed: onScan, textGroup: textGroup),
        ),
      ],
    );
  }
}
