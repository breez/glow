import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/send/widgets/send_actions_row.dart';
import 'package:glow/features/send/widgets/send_approve_button.dart';
import 'package:glow/features/send/widgets/send_form.dart';

class SendLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final AutoSizeGroup textGroup;
  final FocusNode focusNode;
  final bool isValidating;
  final String errorMessage;
  final VoidCallback onPaste;
  final VoidCallback onScan;
  final ValueChanged<String> onSubmit;
  final VoidCallback onApprove;

  const SendLayout({
    super.key,
    required this.formKey,
    required this.controller,
    required this.textGroup,
    required this.focusNode,
    required this.isValidating,
    required this.errorMessage,
    required this.onPaste,
    required this.onScan,
    required this.onSubmit,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Send Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            decoration: ShapeDecoration(
              color: theme.colorScheme.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                SendForm(
                  controller: controller,
                  focusNode: focusNode,
                  errorMessage: errorMessage,
                  onSubmit: onSubmit,
                ),
                const SizedBox(height: 36),
                SendActionsRow(onPaste: onPaste, onScan: onScan, textGroup: textGroup),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SendApproveButton(controller: controller, isValidating: isValidating, onApprove: onApprove),
        ),
      ),
    );
  }
}
