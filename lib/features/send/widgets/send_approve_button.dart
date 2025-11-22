import 'package:flutter/material.dart';
import 'package:glow/widgets/bottom_nav_button.dart';

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
    return BottomNavButton(
      text: 'NEXT',
      onPressed: controller.text.isNotEmpty && !isValidating ? onApprove : null,
      loading: isValidating,
      stickToBottom: true,
    );
  }
}
