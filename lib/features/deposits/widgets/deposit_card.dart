import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/deposits/widgets/deposit_error_banner.dart';

/// Individual deposit card widget - Pure UI component
class DepositCard extends StatefulWidget {
  final DepositInfo deposit;
  final bool hasError;
  final bool hasRefund;
  final String formattedTxid;
  final String? formattedErrorMessage;
  final VoidCallback onRetryClaim;
  final VoidCallback onShowRefundInfo;
  final VoidCallback onCopyTxid;

  const DepositCard({
    super.key,
    required this.deposit,
    required this.hasError,
    required this.hasRefund,
    required this.formattedTxid,
    this.formattedErrorMessage,
    required this.onRetryClaim,
    required this.onShowRefundInfo,
    required this.onCopyTxid,
  });

  @override
  State<DepositCard> createState() => _DepositCardState();
}

class _DepositCardState extends State<DepositCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.hasError;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasError ? theme.colorScheme.error.withValues(alpha: 0.3) : theme.dividerColor,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DepositCardHeader(deposit: widget.deposit, isExpanded: _isExpanded, hasError: hasError),
              if (_isExpanded)
                _DepositCardExpandedContent(
                  deposit: widget.deposit,
                  hasError: widget.hasError,
                  hasRefund: widget.hasRefund,
                  formattedTxid: widget.formattedTxid,
                  formattedErrorMessage: widget.formattedErrorMessage,
                  onRetryClaim: widget.onRetryClaim,
                  onShowRefundInfo: widget.onShowRefundInfo,
                  onCopyTxid: widget.onCopyTxid,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header section of deposit card (always visible)
class _DepositCardHeader extends StatelessWidget {
  const _DepositCardHeader({required this.deposit, required this.isExpanded, required this.hasError});

  final DepositInfo deposit;
  final bool isExpanded;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _DepositIconContainer(hasError: hasError),
        const SizedBox(width: 12),
        Expanded(
          child: _DepositAmountInfo(deposit: deposit, hasError: hasError),
        ),
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

/// Icon container with colored background
class _DepositIconContainer extends StatelessWidget {
  const _DepositIconContainer({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasError ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
        size: 20,
      ),
    );
  }
}

/// Amount and status information
class _DepositAmountInfo extends StatelessWidget {
  const _DepositAmountInfo({required this.deposit, required this.hasError});

  final DepositInfo deposit;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${deposit.amountSats.toString()} sats',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          hasError ? 'Failed to claim' : 'Waiting to claim',
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasError ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Expanded content section (shown when card is tapped)
class _DepositCardExpandedContent extends StatelessWidget {
  const _DepositCardExpandedContent({
    required this.deposit,
    required this.hasError,
    required this.hasRefund,
    required this.formattedTxid,
    this.formattedErrorMessage,
    required this.onRetryClaim,
    required this.onShowRefundInfo,
    required this.onCopyTxid,
  });

  final DepositInfo deposit;
  final bool hasError;
  final bool hasRefund;
  final String formattedTxid;
  final String? formattedErrorMessage;
  final VoidCallback onRetryClaim;
  final VoidCallback onShowRefundInfo;
  final VoidCallback onCopyTxid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        _DepositDetailRow(label: 'Transaction', value: formattedTxid, onTap: onCopyTxid),
        const SizedBox(height: 8),
        _DepositDetailRow(label: 'Output', value: '${deposit.vout}'),
        if (hasError && deposit.claimError != null && formattedErrorMessage != null) ...[
          const SizedBox(height: 16),
          DepositErrorBanner(errorMessage: formattedErrorMessage!),
        ],
        const SizedBox(height: 16),
        _RetryClaimButton(onPressed: onRetryClaim),
        if (hasRefund) ...[const SizedBox(height: 8), _ViewRefundButton(onPressed: onShowRefundInfo)],
      ],
    );
  }
}

/// Detail row showing label and value
class _DepositDetailRow extends StatelessWidget {
  const _DepositDetailRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: onTap != null ? theme.colorScheme.primary : null,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Retry claim button
class _RetryClaimButton extends StatelessWidget {
  const _RetryClaimButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Retry Claim'),
      ),
    );
  }
}

/// View refund button
class _ViewRefundButton extends StatelessWidget {
  const _ViewRefundButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.info_outline, size: 18),
        label: const Text('View Refund'),
      ),
    );
  }
}
