import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/home/widgets/transactions/models/transaction_list_state.dart';
import 'package:glow/features/home/widgets/transactions/theme/transaction_list_text_styles.dart';
import 'package:glow/features/home/widgets/transactions/widgets/transaction_list_shimmer.dart';

/// Individual transaction list item widget
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({required this.transaction, super.key, this.onTap});

  final TransactionItemState transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: Theme.of(context).cardTheme.color,
          child: ListTile(
            onTap: onTap,
            leading: _buildAvatarContainer(context),
            title: Transform.translate(offset: const Offset(-8, 0), child: _buildTitle()),
            subtitle: Transform.translate(offset: const Offset(-8, 0), child: _buildSubtitle(context)),
            trailing: _buildAmount(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContainer(BuildContext context) {
    return Container(
      height: 72.0,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            offset: const Offset(0.5, 0.5),
            blurRadius: 5.0,
          ),
        ],
      ),
      child: CircleAvatar(radius: 16, backgroundColor: Colors.white, child: _buildIcon(context)),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isCompleted = transaction.payment.status == PaymentStatus.completed;
    final Color color = transaction.isReceive
        ? Colors.green
        : isCompleted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    IconData icon;
    switch (transaction.payment.method) {
      case PaymentMethod.lightning:
        icon = Icons.bolt;
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

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildTitle() {
    return Text(
      transaction.description.isEmpty ? transaction.formattedMethod : transaction.description,
      style: const TextStyle(fontSize: 12.25, fontWeight: FontWeight.w400, height: 1.2, letterSpacing: 0.25),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color subtitleColor = colorScheme.onSurface;
    final Color statusColor = _getStatusColor(transaction.payment.status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          transaction.formattedTime,
          style: TextStyle(
            color: subtitleColor.withValues(alpha: .7),
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
            height: 1.16,
            letterSpacing: 0.39,
          ),
        ),
        if (transaction.payment.status != PaymentStatus.completed) ...<Widget>[
          const SizedBox(width: 8),
          Text(
            transaction.formattedStatus,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              height: 1.16,
              letterSpacing: 0.39,
              color: statusColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmount(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color amountColor = colorScheme.onSurface;

    final bool hasFees = transaction.payment.fees > BigInt.zero;
    final bool isPending = transaction.payment.status == PaymentStatus.pending;

    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: (hasFees && !isPending) ? MainAxisAlignment.spaceAround : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            transaction.formattedAmountWithSign,
            style: TextStyle(
              color: amountColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.28,
              letterSpacing: 0.5,
            ),
          ),
          if (hasFees && !isPending)
            Text(
              '${transaction.isReceive ? '' : '-'}${transaction.payment.fees} sats',
              style: TextStyle(
                color: amountColor.withValues(alpha: .7),
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                height: 1.16,
                letterSpacing: 0.39,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.completed => Colors.green,
      PaymentStatus.pending => const Color(0xff4D88EC),
      PaymentStatus.failed => Colors.red,
    };
  }
}

/// Empty state widget for transaction list
class TransactionListEmpty extends StatelessWidget {
  const TransactionListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
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
    return const TransactionListShimmer();
  }
}

/// Error state widget for transaction list
class TransactionListError extends StatelessWidget {
  const TransactionListError({required this.error, super.key, this.onRetry});

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
