import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/silent_payment_state.dart';
import 'package:glow/features/send_payment/providers/silent_payment_provider.dart';
import 'package:glow/features/send_payment/screens/silent_payment_layout.dart';

/// Screen for Silent Payment Address (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to SilentPaymentLayout.
class SilentPaymentScreen extends ConsumerWidget {
  final SilentPaymentAddressDetails addressDetails;

  const SilentPaymentScreen({required this.addressDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SilentPaymentState state = ref.watch(silentPaymentProvider(addressDetails));

    // Auto-navigate home after success
    ref.listen<SilentPaymentState>(silentPaymentProvider(addressDetails), (
      SilentPaymentState? previous,
      SilentPaymentState next,
    ) {
      if (next is SilentPaymentSuccess) {
        // Navigate back to home after a short delay
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return SilentPaymentLayout(
      addressDetails: addressDetails,
      state: state,
      onSendPayment: () {
        ref.read(silentPaymentProvider(addressDetails).notifier).sendPayment();
      },
      onRetry: () {
        ref.read(silentPaymentProvider(addressDetails).notifier).retry();
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
