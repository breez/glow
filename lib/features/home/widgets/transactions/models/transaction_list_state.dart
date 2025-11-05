import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

/// State representation for a single transaction item
class TransactionItemState extends Equatable {
  const TransactionItemState({
    required this.payment,
    required this.formattedAmount,
    required this.formattedAmountWithSign,
    required this.formattedTime,
    required this.formattedStatus,
    required this.formattedMethod,
    required this.description,
    required this.isReceive,
  });

  final Payment payment;
  final String formattedAmount;
  final String formattedAmountWithSign;
  final String formattedTime;
  final String formattedStatus;
  final String formattedMethod;
  final String description;
  final bool isReceive;

  @override
  List<Object?> get props => [
    payment.id,
    formattedAmount,
    formattedAmountWithSign,
    formattedTime,
    formattedStatus,
    formattedMethod,
    description,
    isReceive,
  ];
}

/// State representation for transaction list
class TransactionListState extends Equatable {
  const TransactionListState({
    required this.transactions,
    required this.isLoading,
    required this.hasSynced,
    this.error,
  });

  final List<TransactionItemState> transactions;
  final bool isLoading;
  final bool hasSynced;
  final String? error;

  /// Factory for loading state
  factory TransactionListState.loading() {
    return const TransactionListState(transactions: [], isLoading: true, hasSynced: false, error: null);
  }

  /// Factory for loaded state
  factory TransactionListState.loaded({
    required List<TransactionItemState> transactions,
    required bool hasSynced,
  }) {
    return TransactionListState(
      transactions: transactions,
      isLoading: false,
      hasSynced: hasSynced,
      error: null,
    );
  }

  /// Factory for error state
  factory TransactionListState.error(String error) {
    return TransactionListState(transactions: const [], isLoading: false, hasSynced: false, error: error);
  }

  /// Factory for empty state (synced but no transactions)
  factory TransactionListState.empty() {
    return const TransactionListState(transactions: [], isLoading: false, hasSynced: true, error: null);
  }

  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasError => error != null;
  bool get isEmpty => !hasTransactions && !isLoading && hasSynced;

  TransactionListState copyWith({
    List<TransactionItemState>? transactions,
    bool? isLoading,
    bool? hasSynced,
    String? error,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasSynced: hasSynced ?? this.hasSynced,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [transactions, isLoading, hasSynced, error];
}
