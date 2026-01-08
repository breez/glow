import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/bolt12_invoice_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('Bolt12InvoiceNotifier');

/// Provider for BOLT12 invoice payment state
///
/// This provider manages the state for sending a BOLT12 payment
final NotifierProviderFamily<Bolt12InvoiceNotifier, Bolt12InvoiceState, Bolt12InvoiceDetails>
bolt12InvoiceProvider = NotifierProvider.autoDispose
    .family<Bolt12InvoiceNotifier, Bolt12InvoiceState, Bolt12InvoiceDetails>(
      Bolt12InvoiceNotifier.new,
    );

/// Notifier for BOLT12 invoice payment flow
class Bolt12InvoiceNotifier extends Notifier<Bolt12InvoiceState> {
  Bolt12InvoiceNotifier(this.arg);
  final Bolt12InvoiceDetails arg;

  @override
  Bolt12InvoiceState build() {
    // Auto-prepare the payment when the provider is created
    _preparePayment();
    return const Bolt12InvoiceInitial();
  }

  /// Prepare the payment (calculate fees)
  Future<void> _preparePayment() async {
    state = const Bolt12InvoicePreparing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Preparing BOLT12 invoice payment');

      final PrepareSendPaymentResponse response = await paymentService.prepareSendPayment(
        sdk: sdk,
        paymentRequest: arg.invoice.invoice,
        amount: arg.amountMsat ~/ BigInt.from(1000),
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

      state = Bolt12InvoiceReady(
        prepareResponse: response,
        amountSats: response.amount,
        feeSats: feeSats,
      );
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = Bolt12InvoiceError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Send the payment
  Future<void> sendPayment() async {
    final Bolt12InvoiceState currentState = state;

    if (currentState is! Bolt12InvoiceReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = Bolt12InvoiceSending(prepareResponse: currentState.prepareResponse);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending BOLT12 invoice payment');

      final Payment payment = await paymentService.sendPayment(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
      );

      _log.i('Payment sent successfully - ID: ${payment.id}');

      state = Bolt12InvoiceSuccess(payment: payment);

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = Bolt12InvoiceError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Retry payment preparation (in case of error)
  Future<void> retry() async {
    await _preparePayment();
  }
}
