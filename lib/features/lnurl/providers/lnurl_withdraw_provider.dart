import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/lnurl/models/lnurl_withdraw_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('LnurlWithdrawNotifier');

/// Provider for LNURL withdraw state
///
/// This provider manages the state for withdrawing funds via LNURL
final NotifierProviderFamily<LnurlWithdrawNotifier, LnurlWithdrawState, LnurlWithdrawRequestDetails>
lnurlWithdrawProvider = NotifierProvider.autoDispose
    .family<LnurlWithdrawNotifier, LnurlWithdrawState, LnurlWithdrawRequestDetails>(
      LnurlWithdrawNotifier.new,
    );

/// Notifier for LNURL withdraw flow
class LnurlWithdrawNotifier extends Notifier<LnurlWithdrawState> {
  LnurlWithdrawNotifier(this.arg);
  final LnurlWithdrawRequestDetails arg;

  @override
  LnurlWithdrawState build() {
    // Start in initial state, waiting for amount input
    return LnurlWithdrawInitial(
      minWithdrawableMsat: arg.minWithdrawable,
      maxWithdrawableMsat: arg.maxWithdrawable,
    );
  }

  /// Withdraw funds with the specified amount
  Future<void> withdraw({required BigInt amountSats}) async {
    state = const LnurlWithdrawProcessing();

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);

      _log.i('Withdrawing $amountSats sats via LNURL');

      // Validate amount is within range
      final BigInt amountMsat = amountSats * BigInt.from(1000);
      if (amountMsat < arg.minWithdrawable) {
        throw Exception('Amount must be at least ${arg.minWithdrawable ~/ BigInt.from(1000)} sats');
      }
      if (amountMsat > arg.maxWithdrawable) {
        throw Exception('Amount must be at most ${arg.maxWithdrawable ~/ BigInt.from(1000)} sats');
      }

      // Perform LNURL withdraw
      await sdk.lnurlWithdraw(
        request: LnurlWithdrawRequest(amountSats: amountSats, withdrawRequest: arg),
      );

      _log.i('LNURL withdraw successful');
      state = const LnurlWithdrawSuccess();

      // Refresh node info and payments
      ref.invalidate(nodeInfoProvider);
      ref.invalidate(paymentsProvider);
    } catch (e) {
      _log.e('Failed to withdraw: $e');
      state = LnurlWithdrawError(message: _extractErrorMessage(e), technicalDetails: e.toString());
    }
  }

  /// Retry withdrawal (in case of error)
  Future<void> retry({required BigInt amountSats}) async {
    await withdraw(amountSats: amountSats);
  }

  /// Extract user-friendly error message
  String _extractErrorMessage(Object error) {
    final String errorStr = error.toString();

    if (errorStr.contains('insufficient') || errorStr.contains('balance')) {
      return 'Insufficient balance';
    }
    if (errorStr.contains('expired')) {
      return 'Withdraw request has expired';
    }
    if (errorStr.contains('amount')) {
      return 'Invalid amount';
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error, please try again';
    }

    return 'Withdrawal failed';
  }
}
