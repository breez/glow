import 'package:flutter/material.dart';
import 'package:glow/features/wallet/widgets/recovery_phrase_grid.dart';
import 'package:glow/features/widgets/bottom_nav_button.dart';

class PhraseGridScreen extends StatelessWidget {
  final String mnemonic;
  final VoidCallback onNext;
  const PhraseGridScreen({required this.mnemonic, required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write these words')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[BackupPhraseGrid(mnemonic: mnemonic)],
        ),
      ),
      bottomNavigationBar: BottomNavButton(text: 'NEXT', onPressed: onNext),
    );
  }
}
