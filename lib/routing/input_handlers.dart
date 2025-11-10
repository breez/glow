import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:glow/core/providers/input_parser_provider.dart';

final _log = AppLogger.getLogger('InputHandler');

/// Provider for input handling
final inputHandlerProvider = Provider<InputHandler>((ref) {
  return InputHandler(ref);
});

/// Handles parsed payment inputs and routes to appropriate screens
class InputHandler {
  final Ref _ref;

  InputHandler(this._ref);

  /// Handle a payment input string and navigate to the appropriate screen
  Future<void> handleInput(BuildContext context, String input) async {
    _log.i('Handling input');

    try {
      // Parse the input
      final parser = _ref.read(inputParserProvider);
      final result = await parser.parse(input);

      if (!context.mounted) return;

      // Handle the parsed result
      result.when(
        success: (inputType) {
          _log.i('Successfully parsed input as ${inputType.runtimeType}');
          _navigateToPaymentScreen(context, inputType);
        },
        error: (message) {
          _log.e('Failed to parse input: $message');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid payment info: $message')));
        },
      );
    } catch (e) {
      _log.e('Error handling input: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing payment: $e')));
      }
    }
  }

  /// Navigate to the appropriate payment screen based on input type
  void _navigateToPaymentScreen(BuildContext context, InputType inputType) {
    inputType.when(
      bitcoinAddress: (details) {
        _log.i('Navigating to Bitcoin Address screen');
        Navigator.pushNamed(context, AppRoutes.sendBitcoinAddress, arguments: details);
      },
      bolt11Invoice: (details) {
        _log.i('Navigating to BOLT11 screen');
        Navigator.pushNamed(context, AppRoutes.sendBolt11, arguments: details);
      },
      bolt12Invoice: (details) {
        _log.i('Navigating to BOLT12 Invoice screen');
        Navigator.pushNamed(context, AppRoutes.sendBolt12Invoice, arguments: details);
      },
      bolt12Offer: (details) {
        _log.i('Navigating to BOLT12 Offer screen');
        Navigator.pushNamed(context, AppRoutes.sendBolt12Offer, arguments: details);
      },
      lightningAddress: (details) {
        _log.i('Navigating to Lightning Address screen');
        Navigator.pushNamed(context, AppRoutes.sendLightningAddress, arguments: details);
      },
      lnurlPay: (details) {
        _log.i('Navigating to LNURL-Pay screen');
        Navigator.pushNamed(context, AppRoutes.sendLnurlPay, arguments: details);
      },
      silentPaymentAddress: (details) {
        _log.i('Navigating to Silent Payment screen');
        Navigator.pushNamed(context, AppRoutes.sendSilentPayment, arguments: details);
      },
      lnurlAuth: (details) {
        _log.i('Navigating to LNURL-Auth screen');
        Navigator.pushNamed(context, AppRoutes.lnurlAuth, arguments: details);
      },
      url: (_) {
        _log.w('URL input type not supported for navigation');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('URL payments are not supported')));
      },
      bip21: (details) {
        _log.i('Navigating to BIP21 screen');
        Navigator.pushNamed(context, AppRoutes.sendBip21, arguments: details);
      },
      bolt12InvoiceRequest: (details) {
        _log.i('Navigating to BOLT12 Invoice Request screen');
        Navigator.pushNamed(context, AppRoutes.sendBolt12InvoiceRequest, arguments: details);
      },
      lnurlWithdraw: (details) {
        _log.i('Navigating to LNURL-Withdraw screen');
        Navigator.pushNamed(context, AppRoutes.receiveLnurlWithdraw, arguments: details);
      },
      sparkAddress: (details) {
        _log.i('Navigating to Spark Address screen');
        Navigator.pushNamed(context, AppRoutes.sendSparkAddress, arguments: details);
      },
      sparkInvoice: (details) {
        _log.i('Navigating to Spark Invoice screen');
        Navigator.pushNamed(context, AppRoutes.sendSparkInvoice, arguments: details);
      },
    );
  }
}
