import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Full-screen sheet shown when payment is received
///
/// Auto-dismisses after 2.25 seconds and navigates back to home
class PaymentReceivedSheet extends StatefulWidget {
  const PaymentReceivedSheet({required this.amountSats, super.key});

  final BigInt amountSats;

  @override
  State<PaymentReceivedSheet> createState() => _PaymentReceivedSheetState();
}

class _PaymentReceivedSheetState extends State<PaymentReceivedSheet> {
  @override
  void initState() {
    super.initState();

    // Auto-dismiss after 2.25 seconds (matching Misty Breez timing)
    Future<void>.delayed(const Duration(milliseconds: 2250), () {
      if (mounted) {
        // Pop all routes until home screen
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size mediaQuerySize = MediaQuery.of(context).size;
    final ThemeData themeData = Theme.of(context);
    final ColorScheme colorScheme = themeData.colorScheme;

    return Container(
      height: mediaQuerySize.height,
      width: mediaQuerySize.width,
      color: colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Payment received text
            const Text(
              'Payment Received',
              style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 0.25),
              textAlign: TextAlign.center,
            ),
            // Success icon with animation
            Lottie.asset(
              'assets/animations/lottie/payment_sent_dark.json',
              width: 128.0,
              height: 128.0,
              repeat: false,
              fit: BoxFit.fill,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show payment received sheet
void showPaymentReceivedSheet(BuildContext context, BigInt amountSats) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => PaymentReceivedSheet(amountSats: amountSats),
  );
}
