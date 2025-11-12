import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/providers/sdk_provider.dart';

/// Service for handling deposit claim operations
class DepositClaimer {
  const DepositClaimer();

  /// Claims a deposit through the SDK
  Future<void> claimDeposit(WidgetRef ref, DepositInfo deposit) async {
    await ref.read(claimDepositProvider(deposit).future);
  }

  /// Formats transaction ID for display (shortened)
  String formatTxid(String txid) {
    if (txid.length <= 16) {
      return txid;
    }
    return '${txid.substring(0, 8)}...${txid.substring(txid.length - 8)}';
  }

  /// Formats deposit claim error for user-friendly display
  String formatError(DepositClaimError error) {
    return error.when(
      depositClaimFeeExceeded: (String tx, int vout, Fee? maxFee, BigInt actualFee) {
        final String maxFeeStr = (maxFee != null) ? ' (your max: ${formatMaxFee(maxFee)}). ' : '';
        return 'Fee exceeds limit: $actualFee sats needed$maxFeeStr'
            'Tap "Retry Claim" after increasing your maximum deposit claim fee rate(sat/vByte).';
      },
      missingUtxo: (String tx, int vout) => 'Transaction output not found on chain',
      generic: (String message) => message,
    );
  }

  /// Formats max fee for display
  String formatMaxFee(Fee maxFee) {
    return maxFee.when(
      fixed: (BigInt amount) => '$amount sats',
      rate: (BigInt rate) => '~${99 * rate.toInt()} sats ($rate sat/vByte)',
    );
  }

  /// Checks if deposit has an error
  bool hasError(DepositInfo deposit) {
    return deposit.claimError != null;
  }

  /// Checks if deposit has a refund transaction
  bool hasRefund(DepositInfo deposit) {
    return deposit.refundTx != null;
  }
}

/// Provider for the deposit claimer service
final Provider<DepositClaimer> depositClaimerProvider = Provider<DepositClaimer>((Ref ref) {
  return const DepositClaimer();
});
