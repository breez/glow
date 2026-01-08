import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/spark_address_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('SparkAddressNotifier');

/// Details for Spark Address payment including amount
///
/// Spark addresses require the amount to be set by the user.
/// The amount must be provided when preparing the payment.
class SparkAddressPaymentDetails {
  final SparkAddressDetails addressDetails;
  final BigInt amountSats;

  const SparkAddressPaymentDetails({required this.addressDetails, required this.amountSats});
}

/// Provider for Spark Address payment state
///
/// This provider manages the state for sending a Spark Address payment.
/// For Spark addresses, the amount must be set in the request.
final NotifierProviderFamily<SparkAddressNotifier, SparkAddressState, SparkAddressPaymentDetails>
sparkAddressProvider = NotifierProvider.autoDispose
    .family<SparkAddressNotifier, SparkAddressState, SparkAddressPaymentDetails>(
      SparkAddressNotifier.new,
    );

/// Notifier for Spark Address payment flow
class SparkAddressNotifier extends Notifier<SparkAddressState> {
  SparkAddressNotifier(this.arg);
  final SparkAddressPaymentDetails arg;

  @override
  SparkAddressState build() {
    // Auto-prepare the payment when the provider is created
    // (this happens after the user has entered the amount)
    _preparePayment();
    return const SparkAddressPreparing();
  }

  /// Prepare the payment (calculate fees)
  Future<void> _preparePayment() async {
    state = const SparkAddressPreparing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i(
        'Preparing Spark Address payment to ${arg.addressDetails.address} with amount ${arg.amountSats} sats',
      );

      final PrepareSendPaymentResponse response = await paymentService.prepareSendPayment(
        sdk: sdk,
        paymentRequest: arg.addressDetails.address,
        amount: arg.amountSats,
      );

      // Extract fee from payment method
      final SendPaymentMethod paymentMethod = response.paymentMethod;

      if (paymentMethod is! SendPaymentMethod_SparkAddress) {
        throw Exception('Expected SparkAddress payment method, got ${paymentMethod.runtimeType}');
      }

      final BigInt feeSats = paymentMethod.fee;
      final String? tokenIdentifier = paymentMethod.tokenIdentifier;

      _log.i(
        'Payment prepared - Amount: ${response.amount} sats, Fee: $feeSats sats'
        '${tokenIdentifier != null ? ", Token: $tokenIdentifier" : ""}',
      );

      state = SparkAddressReady(
        prepareResponse: response,
        amountSats: response.amount,
        feeSats: feeSats,
        tokenIdentifier: tokenIdentifier,
      );
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = SparkAddressError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Send the payment
  Future<void> sendPayment() async {
    final SparkAddressState currentState = state;

    if (currentState is! SparkAddressReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = SparkAddressSending(prepareResponse: currentState.prepareResponse);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending Spark Address payment');

      final Payment payment = await paymentService.sendPayment(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
      );

      _log.i('Payment sent successfully - ID: ${payment.id}');

      state = SparkAddressSuccess(payment: payment);

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = SparkAddressError(
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
