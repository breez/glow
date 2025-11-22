import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/data_action_button.dart';

class PasteAndScanActions extends ConsumerWidget {
  final VoidCallback onPaste;
  final VoidCallback onScan;
  final AutoSizeGroup textGroup;

  const PasteAndScanActions({
    required this.onPaste,
    required this.onScan,
    required this.textGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: DataActionButton(
            icon: const Icon(Icons.paste, size: DataActionButtonTheme.iconSize),
            label: 'PASTE',
            onPressed: onPaste,
            tooltip: 'Paste Invoice or Lightning Address',
            textGroup: textGroup,
          ),
        ),
        const SizedBox(width: DataActionButtonTheme.spacing),
        Expanded(
          child: DataActionButton(
            icon: const ImageIcon(
              AssetImage('assets/icon/qr_scan.png'),
              size: DataActionButtonTheme.iconSize,
            ),
            label: 'SCAN',
            onPressed: onScan,
            tooltip: 'Scan Invoice or Lightning Address',
            textGroup: textGroup,
          ),
        ),
      ],
    );
  }
}
