import 'package:flutter/material.dart';

class SendApproveButton extends StatelessWidget {
  final TextEditingController controller;
  final bool isValidating;
  final VoidCallback onApprove;

  const SendApproveButton({
    required this.controller,
    required this.isValidating,
    required this.onApprove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: controller.text.isNotEmpty && !isValidating ? onApprove : null,
      child: SizedBox(
        height: 48,
        child: Center(
          child: isValidating
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('NEXT', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
