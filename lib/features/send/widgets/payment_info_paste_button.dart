import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A button that allows pasting from clipboard
class PaymentInfoPasteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final AutoSizeGroup? textGroup;

  const PaymentInfoPasteButton({required this.onPressed, this.textGroup, super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 138.0),
      child: Tooltip(
        message: 'Paste Invoice or Lightning Address',
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.content_paste, size: 20.0),
          label: AutoSizeText(
            'PASTE',
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
