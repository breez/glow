import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/lnurl/models/lnurl_pay_state.dart';
import 'package:glow/features/lnurl/providers/lnurl_pay_provider.dart';
import 'package:glow/features/lnurl/screens/lnurl_pay_layout.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('LnurlPayScreen');

/// Screen for LNURL-Pay / Lightning Address payment (wiring)
///
/// This screen handles the business logic and state management
/// for LNURL-Pay payments. The actual UI is in LnurlPayLayout.
class LnurlPayScreen extends ConsumerWidget {
  final LnurlPayRequestDetails payRequestDetails;

  const LnurlPayScreen({required this.payRequestDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LnurlPayState state = ref.watch(lnurlPayProvider(payRequestDetails));

    // Listen for success state and navigate home
    ref.listen<LnurlPayState>(lnurlPayProvider(payRequestDetails), (
      LnurlPayState? previous,
      LnurlPayState next,
    ) {
      if (next is LnurlPaySuccess) {
        _log.i('LNURL-Pay successful, navigating home');
        // Wait a moment to show success animation
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return LnurlPayLayout(
      payRequestDetails: payRequestDetails,
      state: state,
      onPreparePayment: (BigInt amount, String? comment) {
        ref
            .read(lnurlPayProvider(payRequestDetails).notifier)
            .preparePayment(amountSats: amount, comment: comment);
      },
      onSendPayment: () => ref.read(lnurlPayProvider(payRequestDetails).notifier).sendPayment(),
      onRetry: (BigInt amount, String? comment) {
        ref
            .read(lnurlPayProvider(payRequestDetails).notifier)
            .retry(amountSats: amount, comment: comment);
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
