import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/lnurl/screens/lnurl_auth_layout.dart';
import 'package:glow/features/lnurl/models/lnurl_auth_state.dart';
import 'package:glow/features/lnurl/providers/lnurl_auth_provider.dart';

/// Screen for LNURL Auth (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to LnurlAuthLayout.
class LnurlAuthScreen extends ConsumerWidget {
  final LnurlAuthRequestDetails authDetails;

  const LnurlAuthScreen({required this.authDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LnurlAuthState state = ref.watch(lnurlAuthProvider(authDetails));

    // Auto-navigate back after success
    ref.listen<LnurlAuthState>(lnurlAuthProvider(authDetails), (
      LnurlAuthState? previous,
      LnurlAuthState next,
    ) {
      if (next is LnurlAuthSuccess) {
        // Navigate back after a short delay
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });

    return LnurlAuthLayout(
      authDetails: authDetails,
      state: state,
      onAuthenticate: () {
        ref.read(lnurlAuthProvider(authDetails).notifier).authenticate();
      },
      onRetry: () {
        ref.read(lnurlAuthProvider(authDetails).notifier).authenticate();
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
