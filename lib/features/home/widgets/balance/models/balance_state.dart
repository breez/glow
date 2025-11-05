import 'package:equatable/equatable.dart';

/// State representation for balance display
/// Following State Management principle - explicit state objects
class BalanceState extends Equatable {
  const BalanceState({
    required this.balance,
    required this.isLoading,
    required this.hasSynced,
    required this.formattedBalance,
    this.formattedFiat,
    this.error,
  });

  final BigInt balance;
  final bool isLoading;
  final bool hasSynced;
  final String formattedBalance;
  final String? formattedFiat;
  final String? error;

  /// Factory for loading state
  factory BalanceState.loading() {
    return BalanceState(
      balance: BigInt.zero,
      isLoading: true,
      hasSynced: false,
      formattedBalance: '0',
      formattedFiat: null,
      error: null,
    );
  }

  /// Factory for loaded state
  factory BalanceState.loaded({
    required BigInt balance,
    required bool hasSynced,
    required String formattedBalance,
    String? formattedFiat,
  }) {
    return BalanceState(
      balance: balance,
      isLoading: false,
      hasSynced: hasSynced,
      formattedBalance: formattedBalance,
      formattedFiat: formattedFiat,
      error: null,
    );
  }

  /// Factory for error state
  factory BalanceState.error(String error) {
    return BalanceState(
      balance: BigInt.zero,
      isLoading: false,
      hasSynced: false,
      formattedBalance: '0',
      formattedFiat: null,
      error: error,
    );
  }

  bool get hasBalance => balance > BigInt.zero;
  bool get hasError => error != null;

  BalanceState copyWith({
    BigInt? balance,
    bool? isLoading,
    bool? hasSynced,
    String? formattedBalance,
    String? formattedFiat,
    String? error,
  }) {
    return BalanceState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      hasSynced: hasSynced ?? this.hasSynced,
      formattedBalance: formattedBalance ?? this.formattedBalance,
      formattedFiat: formattedFiat ?? this.formattedFiat,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [balance, isLoading, hasSynced, formattedBalance, formattedFiat, error];
}
