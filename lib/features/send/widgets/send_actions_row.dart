import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/send/widgets/payment_info_paste_button.dart';
import 'package:glow/features/send/widgets/payment_info_scan_button.dart';

class SendActionsRow extends StatelessWidget {
  final VoidCallback onPaste;
  final VoidCallback onScan;
  final AutoSizeGroup textGroup;

  const SendActionsRow({
    required this.onPaste,
    required this.onScan,
    required this.textGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: PaymentInfoPasteButton(onPressed: onPaste, textGroup: textGroup),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: PaymentInfoScanButton(onPressed: onScan, textGroup: textGroup),
        ),
      ],
    );
  }
}
