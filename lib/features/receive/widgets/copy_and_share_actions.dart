import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:glow/services/clipboard_service.dart';

final AutoSizeGroup textGroup = AutoSizeGroup();

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

class CopyAndShareActions extends ConsumerWidget {
  final String copyData;
  final String shareData;

  const CopyAndShareActions({required this.copyData, required this.shareData, super.key});
  // TODO(erdemyerebasmaz): Consider moving copy & share methods outside for better SoC
  void _onCopyPressed(WidgetRef ref, BuildContext context) {
    ref.read(clipboardServiceProvider).copyToClipboard(context, copyData);
  }

  void _onSharePressed() {
    SharePlus.instance.share(ShareParams(title: shareData, text: shareData));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: DataActionButton(
            icon: const IconData(0xe90b, fontFamily: 'icomoon'),
            label: 'COPY',
            onPressed: () => _onCopyPressed(ref, context),
          ),
        ),
        const SizedBox(width: DataActionButtonTheme.spacing),
        Expanded(
          child: DataActionButton(
            icon: const IconData(0xe917, fontFamily: 'icomoon'),
            label: 'SHARE',
            onPressed: _onSharePressed,
          ),
        ),
      ],
    );
  }
}

class DataActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const DataActionButton({required this.icon, required this.label, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: DataActionButtonTheme.constraints,
      child: Tooltip(
        message: label,
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
