import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/features/home/widgets/transactions/theme/transaction_list_text_styles.dart';
import 'package:glow/features/home/widgets/transactions/widgets/transaction_list_shimmer.dart';

/// Individual transaction list item widget
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({super.key, required this.transaction, this.onTap});

  final TransactionItemState transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final amountColor = transaction.isReceive ? Colors.green : colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      leading: _buildIcon(context),
      title: Row(
        children: [
          Expanded(
            child: Text(
              transaction.description.isEmpty ? transaction.formattedMethod : transaction.description,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            transaction.formattedAmountWithSign,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: amountColor),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            transaction.formattedTime,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          if (transaction.payment.status != PaymentStatus.completed) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.payment.status).withValues(alpha: .2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.formattedStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(transaction.payment.status),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = transaction.payment.status == PaymentStatus.completed;
    final color = transaction.isReceive
        ? Colors.green
        : isCompleted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    IconData icon;
    switch (transaction.payment.method) {
      case PaymentMethod.lightning:
        icon = transaction.isReceive ? Icons.bolt : Icons.bolt;
        break;
      case PaymentMethod.deposit:
        icon = Icons.arrow_downward;
        break;
      case PaymentMethod.withdraw:
        icon = Icons.arrow_upward;
        break;
      case PaymentMethod.token:
        icon = Icons.token;
        break;
      default:
        icon = transaction.isReceive ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: .1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.completed => Colors.green,
      PaymentStatus.pending => Colors.orange,
      PaymentStatus.failed => Colors.red,
    };
  }
}

/// Empty state widget for transaction list
class TransactionListEmpty extends StatelessWidget {
  const TransactionListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('Glow is ready to receive funds.', style: TransactionListTextStyles.emptyState),
      ),
    );
  }
}

/// Loading state widget for transaction list
class TransactionListLoading extends StatelessWidget {
  const TransactionListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListShimmer();
  }
}

/// Error state widget for transaction list
class TransactionListError extends StatelessWidget {
  const TransactionListError({super.key, required this.error, this.onRetry});

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
