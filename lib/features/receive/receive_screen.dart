import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/receive/providers/receive_form_controllers.dart';
import 'package:glow/features/receive/providers/receive_provider.dart';
import 'package:glow/features/receive/receive_layout.dart';
import 'package:glow/features/receive/widgets/payment_received_sheet.dart';

class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key});

  void handleSubmit(WidgetRef ref) {
    final ReceiveState state = ref.watch(receiveProvider);

    switch (state.flowStep) {
      case AmountInputFlowStep.inputAmount:
        _submitAmount(ref);
        break;
      case AmountInputFlowStep.initial:
        Navigator.of(ref.context).pop();
        break;
      case AmountInputFlowStep.displayPayment:
        final ReceiveNotifier notifier = ref.read(receiveProvider.notifier);
        notifier.resetAmountFlow();
        break;
      case AmountInputFlowStep.paymentReceived:
        // Payment received sheet is shown via ref.listen, no action needed here
        break;
    }
  }

  void _submitAmount(WidgetRef ref) {
    final ReceiveFormControllers formControllers = ref.read(receiveFormControllersProvider);
    final ReceiveNotifier notifier = ref.read(receiveProvider.notifier);

    if (!(formControllers.formKey.currentState?.validate() ?? false)) {
      return;
    }

    final BigInt amount = BigInt.parse(formControllers.amount.text);

    notifier.generatePaymentRequest(amount, description: formControllers.description.text);
    formControllers.formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReceiveState state = ref.watch(receiveProvider);
    final ReceiveNotifier notifier = ref.read(receiveProvider.notifier);
    final ReceiveFormControllers formControllers = ref.watch(receiveFormControllersProvider);

    // Listen for payment received state and show success sheet
    ref.listen<ReceiveState>(receiveProvider, (ReceiveState? previous, ReceiveState next) {
      if (next.flowStep == AmountInputFlowStep.paymentReceived && next.amountSats != null) {
        showPaymentReceivedSheet(context, next.amountSats!);
      }
    });

    return ReceiveLayout(
      state: state,
      onChangeMethod: notifier.changeMethod,
      onRequest: notifier.startAmountInput,
      goBackInFlow: state.flowStep == AmountInputFlowStep.initial
          ? () => Navigator.of(context).pop()
          : notifier.goBackInFlow,
      formControllers: formControllers,
      onPressed: () => handleSubmit(ref),
    );
  }
}
