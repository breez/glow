import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/bolt11_payment_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('Bolt11PaymentNotifier');

/// Provider for BOLT11 invoice payment state
///
/// This provider manages the state for sending a BOLT11 payment
final NotifierProviderFamily<Bolt11PaymentNotifier, Bolt11PaymentState, Bolt11InvoiceDetails>
bolt11PaymentProvider = NotifierProvider.autoDispose
    .family<Bolt11PaymentNotifier, Bolt11PaymentState, Bolt11InvoiceDetails>(Bolt11PaymentNotifier.new);

/// Notifier for BOLT11 invoice payment flow
class Bolt11PaymentNotifier extends Notifier<Bolt11PaymentState> {
  Bolt11PaymentNotifier(this.arg);
  final Bolt11InvoiceDetails arg;

  @override
  Bolt11PaymentState build() {
    // Auto-prepare the payment when the provider is created
    _preparePayment();
    return const Bolt11PaymentInitial();
  }

  /// Prepare the payment (calculate fees)
  Future<void> _preparePayment() async {
    state = const Bolt11PaymentPreparing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Preparing BOLT11 payment');

      final PrepareSendPaymentResponse response = await paymentService.prepareSendPayment(
        sdk: sdk,
        paymentRequest: arg.invoice.bolt11,
        amount: arg.amountMsat != null ? (arg.amountMsat! ~/ BigInt.from(1000)) : null,
      );

      // Calculate fees based on payment method
      final BigInt feeSats = response.paymentMethod.when(
        bitcoinAddress: (BitcoinAddressDetails address, SendOnchainFeeQuote feeQuote) {
          // For onchain, use medium speed fee as default
          return feeQuote.speedMedium.userFeeSat + feeQuote.speedMedium.l1BroadcastFeeSat;
        },
        bolt11Invoice:
            (Bolt11InvoiceDetails invoiceDetails, BigInt? sparkTransferFeeSats, BigInt lightningFeeSats) {
              return (sparkTransferFeeSats ?? BigInt.zero) + lightningFeeSats;
            },
        sparkAddress: (String address, BigInt fee, String? tokenIdentifier) {
          return fee;
        },
        sparkInvoice: (SparkInvoiceDetails sparkInvoiceDetails, BigInt fee, String? tokenIdentifier) {
          return fee;
        },
      );

      _log.i('Payment prepared - Amount: ${response.amount} sats, Fee: $feeSats sats');

      // Validate balance after calculating fees
      final AsyncValue<BigInt> balanceAsync = ref.read(balanceProvider);
      if (balanceAsync.hasValue) {
        paymentService.validateBalance(
          currentBalance: balanceAsync.value!,
          paymentAmount: response.amount,
          estimatedFee: feeSats,
        );
      }

      state = Bolt11PaymentReady(
        prepareResponse: response,
        amountSats: response.amount,
        feeSats: feeSats,
        description: arg.description,
      );
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = Bolt11PaymentError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Send the payment
  Future<void> sendPayment() async {
    final Bolt11PaymentState currentState = state;

    if (currentState is! Bolt11PaymentReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = Bolt11PaymentSending(prepareResponse: currentState.prepareResponse);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending BOLT11 payment');

      final Payment payment = await paymentService.sendPayment(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
      );

      _log.i('Payment sent successfully - ID: ${payment.id}');

      state = Bolt11PaymentSuccess(payment: payment);

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = Bolt11PaymentError(
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
