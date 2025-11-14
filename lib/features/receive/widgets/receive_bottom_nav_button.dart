import 'package:flutter/material.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/widgets/bottom_nav_button.dart';

class ReceiveBottomNavButton extends StatelessWidget {
  final ReceiveState state;
  final VoidCallback onPressed;

  const ReceiveBottomNavButton({required this.state, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final bool showBottomNav = !state.isLoading && !state.hasError;

    return showBottomNav
        ? BottomNavButton(
            stickToBottom: true,
            onPressed: onPressed,
            text: state.flowStep == AmountInputFlowStep.inputAmount ? 'CREATE' : 'CLOSE',
          )
        : const SizedBox.shrink();
  }
}
