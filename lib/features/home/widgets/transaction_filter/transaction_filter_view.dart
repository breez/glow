import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/widgets/transaction_filter/transaction_filter_provider.dart';
import 'package:glow/features/home/widgets/transaction_filter/widgets/payment_filter_calendar.dart';
import 'package:glow/features/home/widgets/transaction_filter/widgets/payment_filter_dropdown.dart';
import 'package:glow/features/home/widgets/transaction_filter/widgets/payment_filter_exporter.dart';

/// A row of controls for filtering transactions.
class TransactionFilterView extends ConsumerWidget {
  const TransactionFilterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PaymentType> paymentTypes = ref.watch(
      transactionFilterProvider.select((TransactionFilterState state) => state.paymentTypes),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: <Widget>[
            const PaymentFilterExporter(),
            const PaymentsFilterCalendar(),
            const SizedBox(width: 8),
            PaymentFilterDropdown(paymentTypes, (List<PaymentType> value) {
              ref.read(transactionFilterProvider.notifier).setPaymentTypes(value);
            }),
          ],
        ),
      ),
    );
  }
}
