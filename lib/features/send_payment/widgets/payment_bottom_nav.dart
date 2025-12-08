import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/payment_flow_state.dart';
import 'package:glow/widgets/bottom_nav_button.dart';

/// A generic bottom navigation wrapper that handles common payment states.
class PaymentBottomNav extends StatelessWidget {
  /// The current state of the payment flow
  final PaymentFlowState state;

  /// Callback for when payment is in Initial state (e.g., 'NEXT')
  final VoidCallback? onInitial;

  /// Callback for when payment is in Ready state (e.g., 'SEND', 'CONFIRM')
  final VoidCallback? onReady;

  /// Callback for Retry action on Error
  final VoidCallback onRetry;

  /// Callback for Cancel action
  final VoidCallback onCancel;

  /// Label for the Initial state button (default: 'NEXT')
  final String initialLabel;

  /// Label for the Ready state button (default: 'SEND')
  final String readyLabel;

  /// Whether to stick the button to the bottom of the screen
  final bool stickToBottom;

  const PaymentBottomNav({
    required this.state,
    required this.onRetry,
    required this.onCancel,
    this.onInitial,
    this.onReady,
    this.initialLabel = 'NEXT',
    this.readyLabel = 'SEND',
    this.stickToBottom = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Hide button when sending or success
    if (state.isSending || state.isSuccess) {
      return const SizedBox.shrink();
    }

    // Show retry button on error
    if (state.isError) {
      return BottomNavButton(stickToBottom: stickToBottom, text: 'RETRY', onPressed: onRetry);
    }

    // Show ready button
    if (state.isReady && onReady != null) {
      return BottomNavButton(stickToBottom: stickToBottom, text: readyLabel, onPressed: onReady);
    }

    // Show initial button if callback provided
    if (state.isInitial && onInitial != null) {
      return BottomNavButton(stickToBottom: stickToBottom, text: initialLabel, onPressed: onInitial);
    }

    // Hide button when preparing, or state is unknown
    return const SizedBox.shrink();
  }
}
