import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/bolt12_offer_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('Bolt12OfferNotifier');

/// Provider for BOLT12 offer payment state
///
/// This provider manages the state for sending a BOLT12 offer payment
final NotifierProviderFamily<Bolt12OfferNotifier, Bolt12OfferState, Bolt12OfferDetails>
bolt12OfferProvider = NotifierProvider.autoDispose
    .family<Bolt12OfferNotifier, Bolt12OfferState, Bolt12OfferDetails>(Bolt12OfferNotifier.new);

/// Notifier for BOLT12 offer payment flow
class Bolt12OfferNotifier extends Notifier<Bolt12OfferState> {
  Bolt12OfferNotifier(this.arg);
  final Bolt12OfferDetails arg;

  @override
  Bolt12OfferState build() {
    // Start in initial state, waiting for amount input
    final BigInt? minAmountMsat = arg.minAmount?.when(
      bitcoin: (BigInt amountMsat) => amountMsat,
      currency: (String iso4217Code, BigInt fractionalAmount) =>
          null, // Don't support currency amounts
    );

    return Bolt12OfferInitial(minAmountMsat: minAmountMsat);
  }

  /// Prepare the payment with the specified amount
  Future<void> preparePayment({required BigInt amountSats}) async {
    state = const Bolt12OfferPreparing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Preparing BOLT12 offer payment with amount: $amountSats sats');

      // Validate minimum amount if specified
      final Bolt12OfferState currentState = state;
      if (currentState is Bolt12OfferInitial && currentState.minAmountMsat != null) {
        final BigInt minAmountSats = currentState.minAmountMsat! ~/ BigInt.from(1000);
        if (amountSats < minAmountSats) {
          throw Exception('Amount must be at least $minAmountSats sats');
        }
      }

      final PrepareSendPaymentResponse response = await paymentService.prepareSendPayment(
        sdk: sdk,
        paymentRequest: arg.offer.offer,
        amount: amountSats,
      );

      // Calculate fees based on payment method
      final BigInt feeSats = response.paymentMethod.when(
        bitcoinAddress: (BitcoinAddressDetails address, SendOnchainFeeQuote feeQuote) {
          // For onchain, use medium speed fee as default
          return feeQuote.speedMedium.userFeeSat + feeQuote.speedMedium.l1BroadcastFeeSat;
        },
        bolt11Invoice:
            (
              Bolt11InvoiceDetails invoiceDetails,
              BigInt? sparkTransferFeeSats,
              BigInt lightningFeeSats,
            ) {
              return (sparkTransferFeeSats ?? BigInt.zero) + lightningFeeSats;
            },
        sparkAddress: (String address, BigInt fee, String? tokenIdentifier) {
          return fee;
        },
        sparkInvoice:
            (SparkInvoiceDetails sparkInvoiceDetails, BigInt fee, String? tokenIdentifier) {
              return fee;
            },
      );

      _log.i('Payment prepared - Amount: ${response.amount} sats, Fee: $feeSats sats');

      state = Bolt12OfferReady(
        prepareResponse: response,
        amountSats: response.amount,
        feeSats: feeSats,
      );
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = Bolt12OfferError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Send the payment
  Future<void> sendPayment() async {
    final Bolt12OfferState currentState = state;

    if (currentState is! Bolt12OfferReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = Bolt12OfferSending(prepareResponse: currentState.prepareResponse);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending BOLT12 offer payment');

      final Payment payment = await paymentService.sendPayment(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
      );

      _log.i('Payment sent successfully - ID: ${payment.id}');

      state = Bolt12OfferSuccess(payment: payment);

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = Bolt12OfferError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Retry payment preparation (in case of error)
  Future<void> retry({required BigInt amountSats}) async {
    await preparePayment(amountSats: amountSats);
  }
}
