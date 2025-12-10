import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('PaymentService');

/// Provider for the payment service
final Provider<PaymentService> paymentServiceProvider = Provider<PaymentService>((Ref ref) {
  return PaymentService();
});

/// Service for handling payment operations
///
/// This service wraps SDK payment calls and provides error handling
class PaymentService {
  /// Validate that the user has sufficient balance for a payment
  ///
  /// Throws an exception if balance is insufficient
  void validateBalance({
    required BigInt currentBalance,
    required BigInt paymentAmount,
    BigInt? estimatedFee,
  }) {
    final BigInt totalRequired = paymentAmount + (estimatedFee ?? BigInt.zero);

    _log.t('Validating balance - Current: $currentBalance sats, Required: $totalRequired sats');

    if (currentBalance < totalRequired) {
      final String errorMessage = estimatedFee != null
          ? 'Insufficient balance. Required $totalRequired sats ($paymentAmount + $estimatedFee fee), but only $currentBalance sats available.'
          : 'Insufficient balance. Required $paymentAmount sats, but only $currentBalance sats available.';

      _log.w(errorMessage);
      throw Exception(errorMessage);
    }

    _log.t('Balance validation passed');
  }

  /// Prepare a send payment (BOLT11, BOLT12, Spark invoices, etc.)
  ///
  /// Returns the prepare response with calculated fees
  /// Throws an exception if preparation fails
  Future<PrepareSendPaymentResponse> prepareSendPayment({
    required BreezSdk sdk,
    required String paymentRequest,
    BigInt? amount,
    String? tokenIdentifier,
  }) async {
    _log.i('Preparing send payment');

    try {
      final PrepareSendPaymentRequest request = PrepareSendPaymentRequest(
        paymentRequest: paymentRequest,
        amount: amount,
        tokenIdentifier: tokenIdentifier,
      );

      final PrepareSendPaymentResponse response = await sdk.prepareSendPayment(request: request);

      _log.i('Payment prepared successfully - Amount: ${response.amount} sats');

      return response;
    } catch (e) {
      _log.e('Failed to prepare payment: $e');
      rethrow;
    }
  }

  /// Send a payment
  ///
  /// Returns the payment object
  /// Throws an exception if sending fails
  Future<Payment> sendPayment({
    required BreezSdk sdk,
    required PrepareSendPaymentResponse prepareResponse,
    SendPaymentOptions? options,
    String? idempotencyKey,
  }) async {
    _log.i('Sending payment');

    try {
      final SendPaymentRequest request = SendPaymentRequest(
        prepareResponse: prepareResponse,
        options: options,
        idempotencyKey: idempotencyKey,
      );

      final SendPaymentResponse response = await sdk.sendPayment(request: request);

      _log.i('Payment sent successfully - ID: ${response.payment.id}');

      return response.payment;
    } catch (e) {
      _log.e('Failed to send payment: $e');
      rethrow;
    }
  }

  /// Prepare an LNURL-Pay payment
  ///
  /// Returns the prepare response with calculated fees and generated invoice
  /// Throws an exception if preparation fails
  Future<PrepareLnurlPayResponse> prepareLnurlPay({
    required BreezSdk sdk,
    required LnurlPayRequestDetails payRequest,
    required BigInt amountSats,
    String? comment,
    bool? validateSuccessActionUrl,
  }) async {
    _log.i('Preparing LNURL-Pay payment');

    try {
      final PrepareLnurlPayRequest request = PrepareLnurlPayRequest(
        amountSats: amountSats,
        payRequest: payRequest,
        comment: comment,
        validateSuccessActionUrl: validateSuccessActionUrl,
      );

      final PrepareLnurlPayResponse response = await sdk.prepareLnurlPay(request: request);

      _log.i(
        'LNURL-Pay prepared successfully - Amount: ${response.amountSats} sats, Fee: ${response.feeSats} sats',
      );

      return response;
    } catch (e) {
      _log.e('Failed to prepare LNURL-Pay: $e');
      rethrow;
    }
  }

  /// Execute an LNURL-Pay payment
  ///
  /// Returns the payment object
  /// Throws an exception if payment fails
  Future<Payment> lnurlPay({
    required BreezSdk sdk,
    required PrepareLnurlPayResponse prepareResponse,
    String? idempotencyKey,
  }) async {
    _log.i('Executing LNURL-Pay');

    try {
      final LnurlPayRequest request = LnurlPayRequest(
        prepareResponse: prepareResponse,
        idempotencyKey: idempotencyKey,
      );

      final LnurlPayResponse response = await sdk.lnurlPay(request: request);

      _log.i('LNURL-Pay successful - Payment ID: ${response.payment.id}');

      return response.payment;
    } catch (e) {
      _log.e('Failed to execute LNURL-Pay: $e');
      rethrow;
    }
  }

  /// Extract a user-friendly error message from an exception
  String extractErrorMessage(Object error) {
    final String errorStr = error.toString();

    // Remove common exception prefixes
    String message = errorStr
        .replaceFirst('Exception: ', '')
        .replaceFirst('Error: ', '')
        .replaceFirst('BreezSdkException: ', '');

    // Capitalize first letter
    if (message.isNotEmpty) {
      message = message[0].toUpperCase() + message.substring(1);
    }

    return message;
  }
}
