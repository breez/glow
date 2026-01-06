import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/providers/receive_form_controllers.dart';
import 'package:glow/features/receive/widgets/lightning_receive_view.dart';
import 'package:glow/features/receive/widgets/bitcoin_receive_view.dart';
import 'package:glow/features/receive/widgets/amount_input_view.dart';

class ReceiveViewSwitcher extends ConsumerWidget {
  final ReceiveState state;
  final ReceiveFormControllers formControllers;

  const ReceiveViewSwitcher({required this.state, required this.formControllers, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.flowStep == AmountInputFlowStep.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.flowStep == AmountInputFlowStep.initial) {
      return Center(child: Text(state.error ?? 'Unknown error'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: switch (state.flowStep) {
        AmountInputFlowStep.initial => switch (state.method) {
          ReceiveMethod.lightning => const LightningReceiveView(),
          ReceiveMethod.bitcoin => const BitcoinReceiveView(),
        },
        AmountInputFlowStep.inputAmount => AmountInputView(
          method: state.method,
          formControllers: formControllers,
        ),
        AmountInputFlowStep.displayPayment => PaymentDisplayView(state: state),
        AmountInputFlowStep.paymentReceived => _buildPaymentReceivedView(state),
      },
    );
  }

  /// Build the appropriate view for payment received state
  /// For Lightning Address payments (no invoice), show the Lightning Address view
  /// For invoice-based payments, show the payment display view
  Widget _buildPaymentReceivedView(ReceiveState state) {
    // If there's no receivePaymentResponse, this was a Lightning Address payment
    // Show the Lightning Address view as background while the success sheet displays
    if (state.receivePaymentResponse == null) {
      return switch (state.method) {
        ReceiveMethod.lightning => const LightningReceiveView(),
        ReceiveMethod.bitcoin => const BitcoinReceiveView(),
      };
    }

    // For invoice-based payments, show the payment display
    return PaymentDisplayView(state: state);
  }
}
