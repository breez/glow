import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/bolt12_offer_state.dart';
import 'package:glow/features/send_payment/providers/bolt12_offer_provider.dart';
import 'package:glow/features/send_payment/screens/bolt12_offer_layout.dart';

/// Screen for BOLT12 Offer payment (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to Bolt12OfferLayout.
class Bolt12OfferScreen extends ConsumerWidget {
  final Bolt12OfferDetails offerDetails;

  const Bolt12OfferScreen({required this.offerDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Bolt12OfferState state = ref.watch(bolt12OfferProvider(offerDetails));

    // Auto-navigate home after success
    ref.listen<Bolt12OfferState>(bolt12OfferProvider(offerDetails), (
      Bolt12OfferState? previous,
      Bolt12OfferState next,
    ) {
      if (next is Bolt12OfferSuccess) {
        // Navigate back to home after a short delay
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return Bolt12OfferLayout(
      offerDetails: offerDetails,
      state: state,
      onPreparePayment: (BigInt amountSats) {
        ref.read(bolt12OfferProvider(offerDetails).notifier).preparePayment(amountSats: amountSats);
      },
      onSendPayment: () {
        ref.read(bolt12OfferProvider(offerDetails).notifier).sendPayment();
      },
      onRetry: (BigInt amountSats) {
        ref.read(bolt12OfferProvider(offerDetails).notifier).retry(amountSats: amountSats);
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
