import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/services/clipboard_service.dart';
import 'package:glow/services/share_service.dart';
import 'package:glow/widgets/data_action_button.dart';

final AutoSizeGroup textGroup = AutoSizeGroup();

class CopyAndShareActions extends ConsumerWidget {
  final String copyData;
  final String shareData;

  const CopyAndShareActions({required this.copyData, required this.shareData, super.key});

  void _onCopyPressed(WidgetRef ref, BuildContext context) {
    ref.read(clipboardServiceProvider).copyToClipboard(context, copyData);
  }

  void _onSharePressed(WidgetRef ref) {
    ref.read(shareServiceProvider).share(title: shareData, text: shareData);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: DataActionButton(
            icon: const Icon(
              IconData(0xe90b, fontFamily: 'icomoon'),
              size: DataActionButtonTheme.iconSize,
            ),
            label: 'COPY',
            onPressed: () => _onCopyPressed(ref, context),
            textGroup: textGroup,
          ),
        ),
        const SizedBox(width: DataActionButtonTheme.spacing),
        Expanded(
          child: DataActionButton(
            icon: const Icon(
              IconData(0xe917, fontFamily: 'icomoon'),
              size: DataActionButtonTheme.iconSize,
            ),
            label: 'SHARE',
            onPressed: () => _onSharePressed(ref),
            textGroup: textGroup,
          ),
        ),
      ],
    );
  }
}
