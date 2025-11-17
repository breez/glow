import 'package:flutter/material.dart';
import 'package:glow/features/widgets/bottom_nav_button.dart';

class BackupPhraseInfoScreen extends StatefulWidget {
  final VoidCallback onNext;
  const BackupPhraseInfoScreen({required this.onNext, super.key});

  @override
  State<BackupPhraseInfoScreen> createState() => _BackupPhraseInfoScreenState();
}

class _BackupPhraseInfoScreenState extends State<BackupPhraseInfoScreen> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Phrase')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            const Expanded(flex: 2, child: Icon(Icons.info_outline, size: 100, color: Colors.blue)),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: const Text(
                "You will be shown a list of words. Write down the words and store them in a safe place. Without these words, you won't be able to restore from backup and your funds will be lost.",
                style: TextStyle(fontSize: 14.3, letterSpacing: 0.4, height: 1.16),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Theme(
                      data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white),
                      child: Checkbox(
                        value: _checked,
                        onChanged: (bool? v) => setState(() => _checked = v ?? false),
                        activeColor: Colors.white,
                        checkColor: Theme.of(context).canvasColor,
                      ),
                    ),
                    const Text(
                      'I UNDERSTAND',
                      style: TextStyle(
                        fontSize: 14.3,
                        letterSpacing: 1.25,
                        height: 1.16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 88,
        child: _checked ? BottomNavButton(text: 'NEXT', onPressed: widget.onNext) : null,
      ),
    );
  }
}
