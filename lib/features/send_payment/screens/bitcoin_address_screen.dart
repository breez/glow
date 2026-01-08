import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/bitcoin_address_state.dart';
import 'package:glow/features/send_payment/providers/bitcoin_address_provider.dart';
import 'package:glow/features/send_payment/screens/bitcoin_address_layout.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('BitcoinAddressScreen');

/// Screen for Bitcoin Address (onchain) payment (wiring)
///
/// This screen handles the business logic and state management
/// for Bitcoin onchain payments. The actual UI is in BitcoinAddressLayout.
class BitcoinAddressScreen extends ConsumerWidget {
  final BitcoinAddressDetails addressDetails;

  const BitcoinAddressScreen({required this.addressDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BitcoinAddressState state = ref.watch(bitcoinAddressProvider(addressDetails));
    final Map<FeeSpeed, bool>? affordability = ref.watch(
      bitcoinAddressAffordabilityProvider(addressDetails),
    );

    // Listen for success state and navigate home
    ref.listen<BitcoinAddressState>(bitcoinAddressProvider(addressDetails), (
      BitcoinAddressState? previous,
      BitcoinAddressState next,
    ) {
      if (next is BitcoinAddressSuccess) {
        _log.i('Payment successful, navigating home');
        // Wait a moment to show success animation
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return BitcoinAddressLayout(
      addressDetails: addressDetails,
      state: state,
      affordability: affordability,
      onPreparePayment: (BigInt amount) {
        ref.read(bitcoinAddressProvider(addressDetails).notifier).preparePayment(amount);
      },
      onSelectFeeSpeed: (FeeSpeed speed) {
        ref.read(bitcoinAddressProvider(addressDetails).notifier).selectFeeSpeed(speed);
      },
      onSendPayment: () => ref.read(bitcoinAddressProvider(addressDetails).notifier).sendPayment(),
      onRetry: (BigInt amount) =>
          ref.read(bitcoinAddressProvider(addressDetails).notifier).preparePayment(amount),
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
