// TODO(erdemyerebasmaz): Apply SoC principles w/ feature-first architecture to deposits feature
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:glow/core/utils/clipboard.dart';

class UnclaimedDepositsScreen extends ConsumerWidget {
  const UnclaimedDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsAsync = ref.watch(unclaimedDepositsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Deposits')),
      body: depositsAsync.when(
        data: (deposits) {
          if (deposits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'All deposits claimed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: deposits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _DepositCard(deposit: deposits[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load deposits', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepositCard extends ConsumerStatefulWidget {
  final DepositInfo deposit;

  const _DepositCard({required this.deposit});

  @override
  ConsumerState<_DepositCard> createState() => _DepositCardState();
}

class _DepositCardState extends ConsumerState<_DepositCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.deposit.claimError != null;

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasError
                          ? theme.colorScheme.error.withValues(alpha: 0.1)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.deposit.amountSats.toString()} sats',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasError ? 'Failed to claim' : 'Waiting to claim',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasError
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  'Transaction',
                  _formatTxid(widget.deposit.txid),
                  onTap: () => copyToClipboard(context, widget.deposit.txid),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(context, 'Output', '${widget.deposit.vout}'),
                if (hasError) ...[const SizedBox(height: 16), _buildErrorBanner(context)],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _retryClaim(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry Claim'),
                  ),
                ),
                if (widget.deposit.refundTx != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRefundInfo(),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Refund'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {VoidCallback? onTap}) {
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

  Widget _buildErrorBanner(BuildContext context) {
    final theme = Theme.of(context);
    final error = widget.deposit.claimError!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claim Error',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatError(error),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTxid(String txid) {
    if (txid.length <= 16) return txid;
    return '${txid.substring(0, 8)}...${txid.substring(txid.length - 8)}';
  }

  String _formatError(DepositClaimError error) {
    return error.when(
      depositClaimFeeExceeded: (tx, vout, maxFee, actualFee) {
        final maxFeeStr = maxFee.when(
          fixed: (amount) => '$amount sats',
          rate: (rate) => '~${99 * rate.toInt()} sats ($rate sat/vByte)',
        );
        return 'Fee exceeds limit: $actualFee sats needed (your max: $maxFeeStr). Tap "Retry Claim" after increasing your maximum deposit claim fee rate(sat/vByte).';
      },
      missingUtxo: (tx, vout) => 'Transaction output not found on chain',
      generic: (message) => message,
    );
  }

  Future<void> _retryClaim() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Claiming deposit...')],
              ),
            ),
          ),
        ),
      );

      await ref.read(claimDepositProvider(widget.deposit).future);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit claimed successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showRefundInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refund Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A refund transaction is available for this deposit. This allows you to recover your funds back to an on-chain address.',
            ),
            if (widget.deposit.refundTxId != null) ...[
              const SizedBox(height: 16),
              const Text('Refund TX ID:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              SelectableText(
                widget.deposit.refundTxId!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}
