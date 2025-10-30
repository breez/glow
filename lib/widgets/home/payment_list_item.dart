import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/screens/payment_details_screen.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/utils/payment_helpers.dart';

class PaymentListItem extends StatelessWidget {
  final Payment payment;

  const PaymentListItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final isReceive = payment.paymentType == PaymentType.receive;

    return ListTile(
      onTap: () => _navigateToDetails(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: _PaymentIcon(isReceive: isReceive),
      title: _PaymentTitle(payment: payment),
      subtitle: _PaymentSubtitle(payment: payment),
      trailing: _PaymentAmount(payment: payment, isReceive: isReceive),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentDetailsScreen(payment: payment)));
  }
}

class _PaymentIcon extends StatelessWidget {
  final bool isReceive;

  const _PaymentIcon({required this.isReceive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_iconData, color: _iconColor, size: 20),
    );
  }

  Color get _iconColor => isReceive ? Colors.green : Colors.orange;

  IconData get _iconData => isReceive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
}

class _PaymentTitle extends StatelessWidget {
  final Payment payment;

  const _PaymentTitle({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Text(
      getPaymentTitle(payment),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.3),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _PaymentSubtitle extends StatelessWidget {
  final Payment payment;

  const _PaymentSubtitle({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        formatTimestamp(payment.timestamp),
        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _PaymentAmount extends StatelessWidget {
  final Payment payment;
  final bool isReceive;

  const _PaymentAmount({required this.payment, required this.isReceive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${isReceive ? '+' : '-'}${formatSats(payment.amount)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        SizedBox(height: 16, child: payment.fees > BigInt.zero ? _FeeAmount(fees: payment.fees) : null),
      ],
    );
  }
}

class _FeeAmount extends StatelessWidget {
  final BigInt fees;

  const _FeeAmount({required this.fees});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        'fee ${formatSats(fees)}',
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
