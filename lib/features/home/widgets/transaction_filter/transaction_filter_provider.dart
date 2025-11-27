import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionFilterState extends Equatable {
  final List<PaymentType> paymentTypes;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({this.paymentTypes = const <PaymentType>[], this.startDate, this.endDate});

  TransactionFilterState copyWith({List<PaymentType>? paymentTypes, DateTime? startDate, DateTime? endDate}) {
    return TransactionFilterState(
      paymentTypes: paymentTypes ?? this.paymentTypes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => <Object?>[paymentTypes, startDate, endDate];
}

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

final NotifierProvider<TransactionFilterNotifier, TransactionFilterState> transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(() => TransactionFilterNotifier());
