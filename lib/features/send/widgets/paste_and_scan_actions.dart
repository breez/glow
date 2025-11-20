import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataActionButtonTheme {
  static const BoxConstraints constraints = BoxConstraints(minHeight: 48.0, minWidth: 138.0);

  static const TextStyle textStyle = TextStyle(
    fontSize: 16,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w500,
    height: 1.24,
  );

  static const double borderRadius = 8.0;
  static const double iconSize = 20.0;
  static const double spacing = 32.0;

  static ButtonStyle get buttonStyle => OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
  );
}

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
            icon: Icons.paste,
            label: 'PASTE',
            onPressed: onPaste,
            tooltip: 'Paste Invoice or Lightning Address',
            textGroup: textGroup,
          ),
        ),
        const SizedBox(width: DataActionButtonTheme.spacing),
        Expanded(
          child: DataActionButton(
            // TODO(erdemyerebasmaz): Use 'assets/icons/qr_scan.png' after it's added
            icon: Icons.qr_code,
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

class DataActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String tooltip;
  final AutoSizeGroup textGroup;

  const DataActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.textGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: DataActionButtonTheme.constraints,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton.icon(
          style: DataActionButtonTheme.buttonStyle,
          icon: Icon(icon, size: DataActionButtonTheme.iconSize),
          label: AutoSizeText(
            label,
            style: DataActionButtonTheme.textStyle,
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
