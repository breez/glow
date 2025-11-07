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
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(Icons.content_paste, size: 20.0),
        label: AutoSizeText(
          'PASTE',
          style: Theme.of(context).textTheme.labelLarge,
          maxLines: 1,
          group: textGroup,
          minFontSize: 12,
          stepGranularity: 0.1,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
