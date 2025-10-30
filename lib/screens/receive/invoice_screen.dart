import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/widgets/receive/copyable_card.dart';
import 'package:glow/widgets/receive/error_view.dart';
import 'package:glow/widgets/receive/qr_code_card.dart';

/// Screen for displaying a generated Lightning invoice
class InvoiceScreen extends ConsumerWidget {
  final BigInt amountSats;
  final VoidCallback onBack;

  const InvoiceScreen({super.key, required this.amountSats, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiveResponse = ref.watch(
      receivePaymentProvider(
        ReceivePaymentRequest(
          paymentMethod: ReceivePaymentMethod.bolt11Invoice(description: 'Payment', amountSats: amountSats),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      ),
      body: receiveResponse.when(
        data: (response) => _InvoiceContent(amountSats: amountSats, response: response),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            ErrorView(message: 'Failed to generate invoice', error: err.toString(), onRetry: onBack),
      ),
    );
  }
}

/// Invoice content display
class _InvoiceContent extends StatelessWidget {
  final BigInt amountSats;
  final ReceivePaymentResponse response;

  const _InvoiceContent({required this.amountSats, required this.response});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            formatSats(amountSats),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: -2),
          ),
          const Text('sats', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),
          QRCodeCard(data: response.paymentRequest),
          const SizedBox(height: 32),
          CopyableCard(title: 'Lightning Invoice', content: response.paymentRequest),
          if (response.feeSats > BigInt.zero) ...[
            const SizedBox(height: 16),
            Text(
              'Fee: ${formatSats(response.feeSats)} sats',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
