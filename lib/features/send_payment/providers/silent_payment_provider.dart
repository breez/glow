import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/silent_payment_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('SilentPaymentNotifier');

/// Provider for Silent Payment Address state
///
/// This provider manages the state for sending a silent payment
final NotifierProviderFamily<SilentPaymentNotifier, SilentPaymentState, SilentPaymentAddressDetails>
silentPaymentProvider = NotifierProvider.autoDispose
    .family<SilentPaymentNotifier, SilentPaymentState, SilentPaymentAddressDetails>(
      SilentPaymentNotifier.new,
    );

/// Notifier for Silent Payment Address flow
class SilentPaymentNotifier extends Notifier<SilentPaymentState> {
  SilentPaymentNotifier(this.arg);
  final SilentPaymentAddressDetails arg;

  @override
  SilentPaymentState build() {
    // Auto-prepare the payment when the provider is created
    _preparePayment();
    return const SilentPaymentInitial();
  }

  /// Prepare the payment (calculate fees)
  Future<void> _preparePayment() async {
    state = const SilentPaymentPreparing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Preparing Silent Payment to ${arg.address}');

      final PrepareSendPaymentResponse response = await paymentService.prepareSendPayment(
        sdk: sdk,
        paymentRequest: arg.address,
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

      // Validate balance after calculating fees
      final AsyncValue<BigInt> balanceAsync = ref.read(balanceProvider);
      if (balanceAsync.hasValue) {
        paymentService.validateBalance(
          currentBalance: balanceAsync.value!,
          paymentAmount: response.amount,
          estimatedFee: feeSats,
        );
      }

      state = SilentPaymentReady(
        prepareResponse: response,
        amountSats: response.amount,
        feeSats: feeSats,
      );
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = SilentPaymentError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Send the payment
  Future<void> sendPayment() async {
    final SilentPaymentState currentState = state;

    if (currentState is! SilentPaymentReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = SilentPaymentSending(prepareResponse: currentState.prepareResponse);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending Silent Payment');

      final Payment payment = await paymentService.sendPayment(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
      );

      _log.i('Payment sent successfully - ID: ${payment.id}');

      state = SilentPaymentSuccess(payment: payment);

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = SilentPaymentError(
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
