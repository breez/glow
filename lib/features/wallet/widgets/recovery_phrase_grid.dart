import 'package:flutter/material.dart';
import 'package:glow/core/utils/clipboard.dart';

class RecoveryPhraseGrid extends StatelessWidget {
  final String mnemonic;
  final bool showCopyButton;

  const RecoveryPhraseGrid({super.key, required this.mnemonic, this.showCopyButton = true});

  List<String> get _words => mnemonic.split(' ');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Recovery Phrase', style: Theme.of(context).textTheme.titleMedium)),
                if (showCopyButton)
                  IconButton(
                    icon: Icon(Icons.copy, size: 20),
                    onPressed: () => copyToClipboard(context, mnemonic),
                  ),
              ],
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (_, i) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('${i + 1}.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(width: 8),
                    Text(_words[i], style: TextStyle(fontSize: 14, fontFamily: 'monospace')),
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
