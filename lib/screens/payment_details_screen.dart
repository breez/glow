import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              children: [
                Text(
                  _formatSats(payment.amount),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'sats',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Details
          _buildDetailRow(context, 'Status', _formatStatus(payment.status)),
          _buildDetailRow(context, 'Type', _formatType(payment.paymentType)),
          _buildDetailRow(context, 'Method', _formatMethod(payment.method)),
          if (payment.fees > BigInt.zero)
            _buildDetailRow(context, 'Fee', '${_formatSats(payment.fees)} sats'),
          _buildDetailRow(context, 'Date', _formatDate(payment.timestamp)),

          const Divider(height: 32),

          _buildDetailRow(context, 'Payment ID', payment.id, copyable: true),

          // Payment-specific details
          if (payment.details != null) ...[
            const Divider(height: 32),
            ..._buildPaymentSpecificDetails(context, payment.details!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                if (copyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentSpecificDetails(BuildContext context, PaymentDetails details) {
    return switch (details) {
      PaymentDetails_Lightning(
        :final description,
        :final preimage,
        :final invoice,
        :final paymentHash,
        :final destinationPubkey,
      ) =>
        [
          if (description?.isNotEmpty == true) _buildDetailRow(context, 'Description', description!),
          _buildDetailRow(context, 'Invoice', invoice, copyable: true),
          _buildDetailRow(context, 'Payment Hash', paymentHash, copyable: true),
          if (preimage?.isNotEmpty == true) _buildDetailRow(context, 'Preimage', preimage!, copyable: true),
          _buildDetailRow(context, 'Destination', destinationPubkey, copyable: true),
        ],
      PaymentDetails_Token(:final metadata, :final txHash) => [
        _buildDetailRow(context, 'Token', metadata.name),
        _buildDetailRow(context, 'Ticker', metadata.ticker),
        _buildDetailRow(context, 'TX Hash', txHash, copyable: true),
      ],
      PaymentDetails_Withdraw(:final txId) => [_buildDetailRow(context, 'TX ID', txId, copyable: true)],
      PaymentDetails_Deposit(:final txId) => [_buildDetailRow(context, 'TX ID', txId, copyable: true)],
      PaymentDetails_Spark() => [],
    };
  }

  String _formatSats(BigInt sats) {
    final str = sats.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      buffer.write(str[i]);
      final position = length - i - 1;
      if (position > 0 && position % 3 == 0) {
        buffer.write(',');
      }
    }

    return '$buffer';
  }

  String _formatStatus(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.completed => 'Completed',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.failed => 'Failed',
    };
  }

  String _formatType(PaymentType type) {
    return switch (type) {
      PaymentType.send => 'Send',
      PaymentType.receive => 'Receive',
    };
  }

  String _formatMethod(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.lightning => 'Lightning',
      PaymentMethod.spark => 'Spark',
      PaymentMethod.token => 'Token',
      PaymentMethod.deposit => 'Deposit',
      PaymentMethod.withdraw => 'Withdraw',
      PaymentMethod.unknown => 'Unknown',
    };
  }

  String _formatDate(BigInt timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
