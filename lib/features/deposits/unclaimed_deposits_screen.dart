import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:glow/core/utils/clipboard.dart';
import 'package:glow/features/deposits/providers/deposit_claimer.dart';
import 'package:glow/features/deposits/unclaimed_deposits_layout.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:glow/features/deposits/widgets/deposit_card.dart';
import 'package:glow/features/deposits/models/unclaimed_deposits_state.dart';

final log = AppLogger.getLogger('UnclaimedDepositsScreen');

/// Unclaimed Deposits Screen - handles setup and business logic coordination
/// - UnclaimedDepositsScreen: setup, lifecycle, and business logic coordination
/// - UnclaimedDepositsLayout: pure presentation widget
/// - DepositClaimer: claim/retry logic (testable service)
class UnclaimedDepositsScreen extends ConsumerWidget {
  const UnclaimedDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsAsync = ref.watch(unclaimedDepositsProvider);
    final claimer = ref.read(depositClaimerProvider);

    // Map DepositInfo to DepositCardData for UI
    AsyncValue<List<DepositCardData>> cardDataAsync = depositsAsync.when(
      data: (deposits) => AsyncData(
        deposits.map((deposit) {
          final hasError = claimer.hasError(deposit);
          final hasRefund = claimer.hasRefund(deposit);
          final formattedTxid = claimer.formatTxid(deposit.txid);
          final formattedErrorMessage = hasError && deposit.claimError != null
              ? claimer.formatError(deposit.claimError!)
              : null;
          return DepositCardData(
            deposit: deposit,
            hasError: hasError,
            hasRefund: hasRefund,
            formattedTxid: formattedTxid,
            formattedErrorMessage: formattedErrorMessage,
          );
        }).toList(),
      ),
      loading: () => const AsyncLoading(),
      error: (err, stack) => AsyncError(err, stack),
    );

    Widget buildDepositCard(DepositCardData cardData) {
      final deposit = cardData.deposit;
      return DepositCard(
        deposit: deposit,
        hasError: cardData.hasError,
        hasRefund: cardData.hasRefund,
        formattedTxid: cardData.formattedTxid,
        formattedErrorMessage: cardData.formattedErrorMessage,
        onRetryClaim: () => _handleRetryClaim(context, ref, deposit),
        onShowRefundInfo: () => _showRefundInfo(context, deposit),
        onCopyTxid: () => copyToClipboard(context, deposit.txid),
      );
    }

    return UnclaimedDepositsLayout(
      depositsAsync: cardDataAsync,
      onRetryClaim: (cardData) => _handleRetryClaim(context, ref, cardData.deposit),
      onShowRefundInfo: (cardData) => _showRefundInfo(context, cardData.deposit),
      onCopyTxid: (cardData) => copyToClipboard(context, cardData.deposit.txid),
      depositCardBuilder: buildDepositCard,
    );
  }

  Future<void> _handleRetryClaim(BuildContext context, WidgetRef ref, DepositInfo deposit) async {
    log.i('Retrying claim for deposit: ${deposit.txid}');

    final claimer = ref.read(depositClaimerProvider);

    try {
      _showClaimingDialog(context);

      await claimer.claimDeposit(ref, deposit);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSuccessSnackBar(context);
        log.i('Deposit claimed successfully: ${deposit.txid}');
      }
    } catch (e) {
      log.w('Failed to claim deposit: ${deposit.txid}', error: e);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  void _showClaimingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Claiming deposit...')],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deposit claimed successfully!'), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to claim: $error'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showRefundInfo(BuildContext context, DepositInfo deposit) {
    log.i('Showing refund info for deposit: ${deposit.txid}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refund Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A refund transaction is available for this deposit. This allows you to recover your funds back to an on-chain address.',
            ),
            if (deposit.refundTxId != null) ...[
              const SizedBox(height: 16),
              const Text('Refund TX ID:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              SelectableText(
                deposit.refundTxId!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}
