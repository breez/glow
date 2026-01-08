import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/transaction_filter/models/transaction_filter_state.dart';

class TransactionFilterNotifier extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() {
    return const TransactionFilterState();
  }

  void setPaymentTypes(List<PaymentType> paymentTypes) {
    state = state.copyWith(paymentTypes: paymentTypes);
  }

  void setDateRange(DateTime startDate, DateTime endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void clearDateRange() {
    state = TransactionFilterState(paymentTypes: state.paymentTypes);
  }

  void clearAllFilters() {
    state = const TransactionFilterState();
  }
}

final NotifierProvider<TransactionFilterNotifier, TransactionFilterState>
transactionFilterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
  () => TransactionFilterNotifier(),
);
