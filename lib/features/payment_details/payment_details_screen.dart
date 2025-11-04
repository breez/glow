import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_details_layout.dart';
import 'models/payment_details_state.dart';
import 'services/payment_formatter.dart';

/// Provider for PaymentFormatter service
final paymentFormatterProvider = Provider<PaymentFormatter>((ref) {
  return const PaymentFormatter();
});

/// Provider for PaymentDetailsState factory
final paymentDetailsStateFactoryProvider = Provider<PaymentDetailsStateFactory>((ref) {
  final formatter = ref.watch(paymentFormatterProvider);
  return PaymentDetailsStateFactory(formatter);
});

/// Provider for PaymentDetailsState based on a Payment
final paymentDetailsStateProvider = Provider.family<PaymentDetailsState, Payment>((ref, payment) {
  final factory = ref.watch(paymentDetailsStateFactoryProvider);
  return factory.createState(payment);
});

/// Screen widget responsible for setting up dependencies and injecting state
/// - PaymentDetailsScreen: handles setup and dependency injection
/// - PaymentDetailsLayout: pure presentation widget
class PaymentDetailsScreen extends ConsumerWidget {
  const PaymentDetailsScreen({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create state from payment
    final state = ref.watch(paymentDetailsStateProvider(payment));

    // Return pure presentation widget
    return PaymentDetailsLayout(state: state);
  }
}
