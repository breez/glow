import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/spark_invoice_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('SparkInvoiceNotifier');

/// Provider for Spark Invoice payment state
///
/// This provider manages the state for sending a Spark Invoice payment.
/// For Spark invoices, the amount is optional - it's only required if the
/// invoice doesn't specify an amount. If the invoice specifies an amount,
/// providing a different amount is not supported.
final NotifierProviderFamily<SparkInvoiceNotifier, SparkInvoiceState, SparkInvoiceDetails>
sparkInvoiceProvider = NotifierProvider.autoDispose
    .family<SparkInvoiceNotifier, SparkInvoiceState, SparkInvoiceDetails>(SparkInvoiceNotifier.new);

/// Notifier for Spark Invoice payment flow
///
/// Spark invoices may optionally specify an amount. If they do, that amount
/// must be used. If they don't, the amount must be provided by the user.
class SparkInvoiceNotifier extends Notifier<SparkInvoiceState> {
  SparkInvoiceNotifier(this.arg);
  final SparkInvoiceDetails arg;

  @override
  SparkInvoiceState build() {
    // Start in initial state - user needs to provide amount
    return const SparkInvoiceInitial();
  }

  /// Prepare the payment (calculate fees)
  Future<void> preparePayment({required BigInt amountSats}) async {
    state = const SparkInvoicePreparing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Preparing Spark Invoice payment');

      final PrepareSendPaymentResponse response = await paymentService.prepareSendPayment(
        sdk: sdk,
        paymentRequest: arg.invoice,
        amount: amountSats,
      );

      // Extract fee from payment method
      final SendPaymentMethod paymentMethod = response.paymentMethod;

      if (paymentMethod is! SendPaymentMethod_SparkInvoice) {
        throw Exception('Expected SparkInvoice payment method, got ${paymentMethod.runtimeType}');
      }

      final BigInt feeSats = paymentMethod.fee;
      final String? tokenIdentifier = paymentMethod.tokenIdentifier;

      _log.i(
        'Payment prepared - Amount: ${response.amount} sats, Fee: $feeSats sats'
        '${tokenIdentifier != null ? ", Token: $tokenIdentifier" : ""}',
      );

      state = SparkInvoiceReady(
        prepareResponse: response,
        amountSats: response.amount,
        feeSats: feeSats,
        tokenIdentifier: tokenIdentifier,
        description: arg.description,
      );
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = SparkInvoiceError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Send the payment
  Future<void> sendPayment() async {
    final SparkInvoiceState currentState = state;

    if (currentState is! SparkInvoiceReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = SparkInvoiceSending(prepareResponse: currentState.prepareResponse);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending Spark Invoice payment');

      final Payment payment = await paymentService.sendPayment(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
      );

      _log.i('Payment sent successfully - ID: ${payment.id}');

      state = SparkInvoiceSuccess(payment: payment);

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = SparkInvoiceError(
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
