import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/bolt12_invoice_state.dart';
import 'package:glow/features/send_payment/providers/bolt12_invoice_provider.dart';
import 'package:glow/features/send_payment/screens/bolt12_invoice_layout.dart';

/// Screen for BOLT12 Invoice payment (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to Bolt12InvoiceLayout.
class Bolt12InvoiceScreen extends ConsumerWidget {
  final Bolt12InvoiceDetails invoiceDetails;

  const Bolt12InvoiceScreen({required this.invoiceDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Bolt12InvoiceState state = ref.watch(bolt12InvoiceProvider(invoiceDetails));

    // Auto-navigate home after success
    ref.listen<Bolt12InvoiceState>(bolt12InvoiceProvider(invoiceDetails), (
      Bolt12InvoiceState? previous,
      Bolt12InvoiceState next,
    ) {
      if (next is Bolt12InvoiceSuccess) {
        // Navigate back to home after a short delay
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return Bolt12InvoiceLayout(
      invoiceDetails: invoiceDetails,
      state: state,
      onSendPayment: () {
        ref.read(bolt12InvoiceProvider(invoiceDetails).notifier).sendPayment();
      },
      onRetry: () {
        ref.read(bolt12InvoiceProvider(invoiceDetails).notifier).retry();
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
