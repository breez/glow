import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/transaction_filter/models/transaction_filter_state.dart';
import 'package:glow/features/transaction_filter/providers/transaction_filter_provider.dart';

/// Renders a row of Chips for each active filter.
class ActiveFiltersView extends ConsumerWidget {
  const ActiveFiltersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionFilterState filterState = ref.watch(transactionFilterProvider);
    final DateTime? startDate = filterState.startDate;
    final DateTime? endDate = filterState.endDate;

    final bool hasActiveFilter = startDate != null || endDate != null;

    if (!hasActiveFilter) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 50.0,
          color: Theme.of(context).colorScheme.surfaceContainer,
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
            ],
          ),
        ),
      ),
    );
  }
}
