import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/bitcoin_address_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('BitcoinAddressNotifier');

/// Provider for Bitcoin Address (onchain) payment state
///
/// This provider manages the state for sending a Bitcoin onchain payment
final NotifierProviderFamily<BitcoinAddressNotifier, BitcoinAddressState, BitcoinAddressDetails>
bitcoinAddressProvider = NotifierProvider.autoDispose
    .family<BitcoinAddressNotifier, BitcoinAddressState, BitcoinAddressDetails>(BitcoinAddressNotifier.new);

/// Notifier for Bitcoin Address (onchain) payment flow
class BitcoinAddressNotifier extends Notifier<BitcoinAddressState> {
  BitcoinAddressNotifier(this.arg);
  final BitcoinAddressDetails arg;

  @override
  BitcoinAddressState build() {
    // Start with initial state - user needs to input amount
    return const BitcoinAddressInitial();
  }

  /// Prepare the payment with the specified amount (calculate fees)
  Future<void> preparePayment(BigInt amountSats) async {
    state = BitcoinAddressPreparing(amountSats: amountSats);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);

      _log.i('Preparing Bitcoin Address payment to ${arg.address} for $amountSats sats');

      // For Bitcoin addresses, pass the address and amount separately
      final PrepareSendPaymentRequest request = PrepareSendPaymentRequest(
        paymentRequest: arg.address,
        amount: amountSats,
      );

      final PrepareSendPaymentResponse response = await sdk.prepareSendPayment(request: request);

      // Extract fee quote from payment method
      final SendPaymentMethod paymentMethod = response.paymentMethod;

      if (paymentMethod is! SendPaymentMethod_BitcoinAddress) {
        throw Exception('Expected BitcoinAddress payment method, got ${paymentMethod.runtimeType}');
      }

      final SendOnchainFeeQuote feeQuote = paymentMethod.feeQuote;

      _log.i(
        'Payment prepared - Fees: Slow=${_getTotalFee(feeQuote.speedSlow)} '
        'Medium=${_getTotalFee(feeQuote.speedMedium)} '
        'Fast=${_getTotalFee(feeQuote.speedFast)} sats',
      );

      state = BitcoinAddressReady(prepareResponse: response, amountSats: amountSats, feeQuote: feeQuote);
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = BitcoinAddressError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Change the selected fee speed
  void selectFeeSpeed(FeeSpeed speed) {
    final BitcoinAddressState currentState = state;

    if (currentState is! BitcoinAddressReady) {
      _log.w('Cannot change fee speed - not in ready state');
      return;
    }

    _log.d('Changing fee speed to ${speed.name}');
    state = currentState.copyWith(selectedSpeed: speed);
  }

  /// Send the payment with the selected fee speed
  Future<void> sendPayment() async {
    final BitcoinAddressState currentState = state;

    if (currentState is! BitcoinAddressReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = BitcoinAddressSending(
      prepareResponse: currentState.prepareResponse,
      selectedSpeed: currentState.selectedSpeed,
    );

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending Bitcoin Address payment with ${currentState.selectedSpeed.name} fee');

      // Create send options with selected fee speed
      final SendPaymentOptions options = SendPaymentOptions.bitcoinAddress(
        confirmationSpeed: _mapFeeSpeed(currentState.selectedSpeed),
      );

      final Payment payment = await paymentService.sendPayment(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
        options: options,
      );

      _log.i('Payment sent successfully - ID: ${payment.id}');

      state = BitcoinAddressSuccess(payment: payment);

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send payment: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = BitcoinAddressError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Map fee speed enum to SDK confirmation speed
  OnchainConfirmationSpeed _mapFeeSpeed(FeeSpeed speed) {
    switch (speed) {
      case FeeSpeed.slow:
        return OnchainConfirmationSpeed.slow;
      case FeeSpeed.medium:
        return OnchainConfirmationSpeed.medium;
      case FeeSpeed.fast:
        return OnchainConfirmationSpeed.fast;
    }
  }

  /// Calculate total fee for a fee estimate
  BigInt _getTotalFee(SendOnchainSpeedFeeQuote estimate) {
    return estimate.userFeeSat + estimate.l1BroadcastFeeSat;
  }
}
