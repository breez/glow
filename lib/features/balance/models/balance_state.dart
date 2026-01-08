import 'package:equatable/equatable.dart';

/// State representation for balance display
/// Following State Management principle - explicit state objects
class BalanceState extends Equatable {
  const BalanceState({
    required this.balance,
    required this.hasSynced,
    required this.formattedBalance,
    this.formattedFiat,
    this.error,
  });

  final BigInt balance;
  final bool hasSynced;
  final String formattedBalance;
  final String? formattedFiat;
  final String? error;

  /// Factory for loading state
  factory BalanceState.loading() {
    return BalanceState(balance: BigInt.zero, hasSynced: false, formattedBalance: '0');
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
      hasSynced: hasSynced,
      formattedBalance: formattedBalance,
      formattedFiat: formattedFiat,
    );
  }

  /// Factory for error state
  factory BalanceState.error(String error) {
    return BalanceState(
      balance: BigInt.zero,
      hasSynced: false,
      formattedBalance: '0',
      error: error,
    );
  }

  bool get hasBalance => balance > BigInt.zero;
  bool get hasError => error != null;
  bool get isLoading => !hasSynced && error == null;

  BalanceState copyWith({
    BigInt? balance,
    bool? hasSynced,
    String? formattedBalance,
    String? formattedFiat,
    String? error,
  }) {
    return BalanceState(
      balance: balance ?? this.balance,
      hasSynced: hasSynced ?? this.hasSynced,
      formattedBalance: formattedBalance ?? this.formattedBalance,
      formattedFiat: formattedFiat ?? this.formattedFiat,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[balance, hasSynced, formattedBalance, formattedFiat, error];
}
