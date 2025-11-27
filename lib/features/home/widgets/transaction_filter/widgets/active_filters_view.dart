import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/widgets/transaction_filter/transaction_filter_provider.dart';

/// Renders a row of Chips for each active filter.
class ActiveFiltersView extends ConsumerWidget {
  const ActiveFiltersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionFilterState filterState = ref.watch(transactionFilterProvider);
    final List<PaymentType> paymentTypes = filterState.paymentTypes;
    final DateTime? startDate = filterState.startDate;
    final DateTime? endDate = filterState.endDate;

    final bool hasActiveFilter = paymentTypes.isNotEmpty || startDate != null || endDate != null;

    if (!hasActiveFilter) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          if (startDate != null && endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Chip(
                label: Text(
                  '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                ),
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).clearDateRange();
                },
              ),
            ),
          ...paymentTypes.map(
            (PaymentType type) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Chip(
                label: Text(type == PaymentType.send ? 'Sent' : 'Received'),
                onDeleted: () {
                  final List<PaymentType> newTypes = List<PaymentType>.from(paymentTypes)..remove(type);
                  ref.read(transactionFilterProvider.notifier).setPaymentTypes(newTypes);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
