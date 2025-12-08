import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/spark_address_state.dart';
import 'package:glow/features/send_payment/providers/spark_address_provider.dart';
import 'package:glow/features/send_payment/screens/spark_address_layout.dart';

/// Screen for Spark Address payment (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to SparkAddressLayout.
///
/// For Spark Address payments, the user must provide an amount before
/// the payment can be prepared.
class SparkAddressScreen extends ConsumerStatefulWidget {
  final SparkAddressDetails addressDetails;

  const SparkAddressScreen({required this.addressDetails, super.key});

  @override
  ConsumerState<SparkAddressScreen> createState() => _SparkAddressScreenState();
}

class _SparkAddressScreenState extends ConsumerState<SparkAddressScreen> {
  SparkAddressPaymentDetails? _paymentDetails;

  void _handlePreparePayment(BigInt amountSats) {
    setState(() {
      _paymentDetails = SparkAddressPaymentDetails(
        addressDetails: widget.addressDetails,
        amountSats: amountSats,
      );
    });
  }

  void _handleRetry(BigInt amountSats) {
    setState(() {
      _paymentDetails = SparkAddressPaymentDetails(
        addressDetails: widget.addressDetails,
        amountSats: amountSats,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no payment details yet, show initial state
    if (_paymentDetails == null) {
      return SparkAddressLayout(
        addressDetails: widget.addressDetails,
        state: const SparkAddressInitial(),
        onPreparePayment: _handlePreparePayment,
        onSendPayment: () {},
        onRetry: _handleRetry,
        onCancel: () {
          Navigator.of(context).pop();
        },
      );
    }

    final SparkAddressState state = ref.watch(sparkAddressProvider(_paymentDetails!));

    // Auto-navigate home after success
    ref.listen<SparkAddressState>(sparkAddressProvider(_paymentDetails!), (
      SparkAddressState? previous,
      SparkAddressState next,
    ) {
      if (next is SparkAddressSuccess) {
        // Navigate back to home after a short delay
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return SparkAddressLayout(
      addressDetails: widget.addressDetails,
      state: state,
      onPreparePayment: _handlePreparePayment,
      onSendPayment: () {
        ref.read(sparkAddressProvider(_paymentDetails!).notifier).sendPayment();
      },
      onRetry: _handleRetry,
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
