import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/clipboard_service.dart';

class BackupPhraseGrid extends ConsumerWidget {
  final String mnemonic;
  final bool showCopyButton;

  const BackupPhraseGrid({required this.mnemonic, super.key, this.showCopyButton = true});

  List<String> get _words => mnemonic.split(' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ClipboardService clipboardService = ref.read(clipboardServiceProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(child: Text('Backup Phrase', style: Theme.of(context).textTheme.titleMedium)),
                if (showCopyButton)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => clipboardService.copyToClipboard(context, mnemonic),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (_, int i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Text('${i + 1}.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(_words[i], style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
