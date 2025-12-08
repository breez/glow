import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/lnurl/screens/lnurl_withdraw_layout.dart';
import 'package:glow/features/lnurl/models/lnurl_withdraw_state.dart';
import 'package:glow/features/lnurl/providers/lnurl_withdraw_provider.dart';

/// Screen for LNURL Withdraw (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to LnurlWithdrawLayout.
class LnurlWithdrawScreen extends ConsumerWidget {
  final LnurlWithdrawRequestDetails withdrawDetails;

  const LnurlWithdrawScreen({required this.withdrawDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LnurlWithdrawState state = ref.watch(lnurlWithdrawProvider(withdrawDetails));

    // Auto-navigate home after success
    ref.listen<LnurlWithdrawState>(lnurlWithdrawProvider(withdrawDetails), (
      LnurlWithdrawState? previous,
      LnurlWithdrawState next,
    ) {
      if (next is LnurlWithdrawSuccess) {
        // Navigate back to home after a short delay
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return LnurlWithdrawLayout(
      withdrawDetails: withdrawDetails,
      state: state,
      onWithdraw: (BigInt amountSats) {
        ref.read(lnurlWithdrawProvider(withdrawDetails).notifier).withdraw(amountSats: amountSats);
      },
      onRetry: (BigInt amountSats) {
        ref.read(lnurlWithdrawProvider(withdrawDetails).notifier).retry(amountSats: amountSats);
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
