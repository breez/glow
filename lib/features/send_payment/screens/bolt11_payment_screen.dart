import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/bolt11_payment_state.dart';
import 'package:glow/features/send_payment/providers/bolt11_payment_provider.dart';
import 'package:glow/features/send_payment/screens/bolt11_payment_layout.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('Bolt11PaymentScreen');

/// Screen for BOLT11 invoice payment (wiring)
///
/// This screen handles the business logic and state management
/// for BOLT11 payments. The actual UI is in Bolt11PaymentLayout.
class Bolt11PaymentScreen extends ConsumerWidget {
  final Bolt11InvoiceDetails invoiceDetails;

  const Bolt11PaymentScreen({required this.invoiceDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Bolt11PaymentState state = ref.watch(bolt11PaymentProvider(invoiceDetails));

    // Listen for success state and navigate home
    ref.listen<Bolt11PaymentState>(bolt11PaymentProvider(invoiceDetails), (
      Bolt11PaymentState? previous,
      Bolt11PaymentState next,
    ) {
      if (next is Bolt11PaymentSuccess) {
        _log.i('Payment successful, navigating home');
        // Wait a moment to show success animation
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return Bolt11PaymentLayout(
      invoiceDetails: invoiceDetails,
      state: state,
      onSendPayment: () => ref.read(bolt11PaymentProvider(invoiceDetails).notifier).sendPayment(),
      onRetry: () => ref.read(bolt11PaymentProvider(invoiceDetails).notifier).retry(),
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
