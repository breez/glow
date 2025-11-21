import 'package:flutter/material.dart';
import 'package:glow/features/wallet/widgets/restore_phrase_grid.dart';
import 'package:glow/features/wallet/widgets/warning_card.dart';
import 'package:glow/features/widgets/bottom_nav_button.dart';

class RestoreLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<TextEditingController> mnemonicControllers;
  final List<FocusNode> focusNodes;
  final List<String> Function(String query) getSuggestions;
  final String? mnemonicError;
  final bool isRestoring;
  final Function(int index, String selection) onWordSelected;
  final VoidCallback onPaste;
  final VoidCallback onRestore;

  const RestoreLayout({
    required this.formKey,
    required this.mnemonicControllers,
    required this.focusNodes,
    required this.getSuggestions,
    required this.mnemonicError,
    required this.isRestoring,
    required this.onWordSelected,
    required this.onPaste,
    required this.onRestore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter your backup phrase')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            RestorePhraseGrid(
              controllers: mnemonicControllers,
              focusNodes: focusNodes,
              getSuggestions: getSuggestions,
              onWordSelected: onWordSelected,
              onPaste: onPaste,
            ),
            if (mnemonicError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: WarningCard(message: mnemonicError!, textColor: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavButton(text: 'RESTORE', onPressed: onRestore, loading: isRestoring),
    );
  }
}
