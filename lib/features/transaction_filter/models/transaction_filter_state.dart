import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

class TransactionFilterState extends Equatable {
  final List<PaymentType> paymentTypes;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.paymentTypes = const <PaymentType>[],
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    List<PaymentType>? paymentTypes,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilterState(
      paymentTypes: paymentTypes ?? this.paymentTypes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => <Object?>[paymentTypes, startDate, endDate];
}
