import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/spark_invoice_state.dart';
import 'package:glow/features/send_payment/providers/spark_invoice_provider.dart';
import 'package:glow/features/send_payment/screens/spark_invoice_layout.dart';

/// Screen for Spark Invoice payment (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to SparkInvoiceLayout.
class SparkInvoiceScreen extends ConsumerWidget {
  final SparkInvoiceDetails invoiceDetails;

  const SparkInvoiceScreen({required this.invoiceDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SparkInvoiceState state = ref.watch(sparkInvoiceProvider(invoiceDetails));

    // Auto-navigate home after success
    ref.listen<SparkInvoiceState>(sparkInvoiceProvider(invoiceDetails), (
      SparkInvoiceState? previous,
      SparkInvoiceState next,
    ) {
      if (next is SparkInvoiceSuccess) {
        // Navigate back to home after a short delay
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return SparkInvoiceLayout(
      invoiceDetails: invoiceDetails,
      state: state,
      onPreparePayment: (BigInt amountSats) {
        ref.read(sparkInvoiceProvider(invoiceDetails).notifier).preparePayment(amountSats: amountSats);
      },
      onSendPayment: () {
        ref.read(sparkInvoiceProvider(invoiceDetails).notifier).sendPayment();
      },
      onRetry: (BigInt amountSats) {
        ref.read(sparkInvoiceProvider(invoiceDetails).notifier).retry(amountSats: amountSats);
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
