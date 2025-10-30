import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/widgets/home/payment_list_item.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(paymentsProvider.notifier).refreshIfChanged();
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: payments.when(
          data: (list) => _buildList(context, list),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _TransactionError(error: err),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Payment> payments) {
    if (payments.isEmpty) {
      return _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: payments.length,
      separatorBuilder: (context, index) => _buildDivider(context),
      itemBuilder: (context, index) => PaymentListItem(payment: payments[index]),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 24,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No transactions yet',
        style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _TransactionError extends StatelessWidget {
  final Object error;

  const _TransactionError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
