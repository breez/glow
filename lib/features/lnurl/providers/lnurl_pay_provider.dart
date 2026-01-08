import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/lnurl/models/lnurl_pay_state.dart';
import 'package:glow/features/send_payment/services/payment_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('LnurlPayNotifier');

/// Provider for LNURL-Pay and Lightning Address payment state
///
/// This provider manages the state for sending an LNURL-Pay payment
final NotifierProviderFamily<LnurlPayNotifier, LnurlPayState, LnurlPayRequestDetails>
lnurlPayProvider = NotifierProvider.autoDispose
    .family<LnurlPayNotifier, LnurlPayState, LnurlPayRequestDetails>(LnurlPayNotifier.new);

/// Notifier for LNURL-Pay and Lightning Address payment flow
class LnurlPayNotifier extends Notifier<LnurlPayState> {
  LnurlPayNotifier(this.arg);
  final LnurlPayRequestDetails arg;

  @override
  LnurlPayState build() {
    // Return initial state with the pay request details
    return LnurlPayInitial(
      payRequest: arg,
      minSendable: arg.minSendable,
      maxSendable: arg.maxSendable,
      commentAllowed: arg.commentAllowed,
    );
  }

  /// Prepare the payment (calculate fees and generate invoice)
  Future<void> preparePayment({required BigInt amountSats, String? comment}) async {
    state = const LnurlPayPreparing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Preparing LNURL-Pay payment - Amount: $amountSats sats');

      // Validate amount is within sendable range (convert sats to millisats)
      final BigInt amountMsat = amountSats * BigInt.from(1000);
      if (amountMsat < arg.minSendable || amountMsat > arg.maxSendable) {
        throw Exception(
          'Amount must be between ${arg.minSendable ~/ BigInt.from(1000)} and ${arg.maxSendable ~/ BigInt.from(1000)} sats',
        );
      }

      // Validate comment length
      if (comment != null && comment.length > arg.commentAllowed) {
        throw Exception('Comment must be ${arg.commentAllowed} characters or less');
      }

      final PrepareLnurlPayResponse response = await paymentService.prepareLnurlPay(
        sdk: sdk,
        payRequest: arg,
        amountSats: amountSats,
        comment: comment,
        validateSuccessActionUrl: true,
      );

      _log.i(
        'LNURL-Pay prepared - Amount: ${response.amountSats} sats, Fee: ${response.feeSats} sats',
      );

      // Validate balance after calculating fees
      final AsyncValue<BigInt> balanceAsync = ref.read(balanceProvider);
      if (balanceAsync.hasValue) {
        paymentService.validateBalance(
          currentBalance: balanceAsync.value!,
          paymentAmount: response.amountSats,
          estimatedFee: response.feeSats,
        );
      }

      state = LnurlPayReady(
        prepareResponse: response,
        amountSats: response.amountSats,
        feeSats: response.feeSats,
        comment: comment,
      );
    } catch (e) {
      _log.e('Failed to prepare LNURL-Pay: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = LnurlPayError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Send the payment
  Future<void> sendPayment() async {
    final LnurlPayState currentState = state;

    if (currentState is! LnurlPayReady) {
      _log.w('Cannot send payment - not in ready state');
      return;
    }

    state = LnurlPaySending(prepareResponse: currentState.prepareResponse);

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final PaymentService paymentService = ref.read(paymentServiceProvider);

      _log.i('Sending LNURL-Pay payment');

      final Payment payment = await paymentService.lnurlPay(
        sdk: sdk,
        prepareResponse: currentState.prepareResponse,
      );

      _log.i('LNURL-Pay sent successfully - ID: ${payment.id}');

      state = LnurlPaySuccess(
        payment: payment,
        successAction: currentState.prepareResponse.successAction,
      );

      // Refresh payments list
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to send LNURL-Pay: $e');
      final PaymentService paymentService = ref.read(paymentServiceProvider);
      state = LnurlPayError(
        message: paymentService.extractErrorMessage(e),
        technicalDetails: e.toString(),
      );
    }
  }

  /// Retry payment preparation (in case of error)
  Future<void> retry({required BigInt amountSats, String? comment}) async {
    await preparePayment(amountSats: amountSats, comment: comment);
  }
}
