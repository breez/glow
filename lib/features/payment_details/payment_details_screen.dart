import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/payment_details/payment_details_layout.dart';
import 'package:glow/features/payment_details/models/payment_details_state.dart';
import 'package:glow/features/payment_details/services/payment_formatter.dart';

/// Provider for PaymentFormatter service
final Provider<PaymentFormatter> paymentFormatterProvider = Provider<PaymentFormatter>((Ref ref) {
  return const PaymentFormatter();
});

/// Provider for PaymentDetailsState factory
final Provider<PaymentDetailsStateFactory> paymentDetailsStateFactoryProvider =
    Provider<PaymentDetailsStateFactory>((Ref ref) {
      final PaymentFormatter formatter = ref.watch(paymentFormatterProvider);
      return PaymentDetailsStateFactory(formatter);
    });

/// Provider for PaymentDetailsState based on a Payment
final ProviderFamily<PaymentDetailsState, Payment> paymentDetailsStateProvider =
    Provider.family<PaymentDetailsState, Payment>((Ref ref, Payment payment) {
      final PaymentDetailsStateFactory factory = ref.watch(paymentDetailsStateFactoryProvider);
      return factory.createState(payment);
    });

/// Screen widget responsible for setting up dependencies and injecting state
/// - PaymentDetailsScreen: handles setup and dependency injection
/// - PaymentDetailsLayout: pure presentation widget
class PaymentDetailsScreen extends ConsumerWidget {
  const PaymentDetailsScreen({required this.payment, super.key});

  final Payment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create state from payment
    final PaymentDetailsState state = ref.watch(paymentDetailsStateProvider(payment));

    // Return pure presentation widget
    return PaymentDetailsLayout(state: state);
  }
}
