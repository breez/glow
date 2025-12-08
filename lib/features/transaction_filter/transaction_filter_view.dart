import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/transaction_filter/models/transaction_filter_state.dart';
import 'package:glow/features/transaction_filter/providers/transaction_filter_provider.dart';
import 'package:glow/features/transaction_filter/widgets/payment_filter_calendar.dart';
import 'package:glow/features/transaction_filter/widgets/payment_filter_dropdown.dart';
import 'package:glow/features/transaction_filter/widgets/payment_filter_exporter.dart';

/// A row of controls for filtering transactions.
class TransactionFilterView extends ConsumerWidget {
  const TransactionFilterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PaymentType> paymentTypes = ref.watch(
      transactionFilterProvider.select((TransactionFilterState state) => state.paymentTypes),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Row(
            children: <Widget>[
              const PaymentFilterExporter(),
              const PaymentsFilterCalendar(),
              PaymentFilterDropdown(paymentTypes, (List<PaymentType> value) {
                ref.read(transactionFilterProvider.notifier).setPaymentTypes(value);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
