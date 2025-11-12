import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

/// State model for the unclaimed deposits screen
sealed class UnclaimedDepositsState {
  const UnclaimedDepositsState();

  /// Check if currently loading
  bool get isLoading => this is UnclaimedDepositsLoading;

  /// Check if loaded successfully (with or without deposits)
  bool get isLoaded => this is UnclaimedDepositsLoaded;

  /// Check if in error state
  bool get isError => this is UnclaimedDepositsError;

  /// Check if has deposits (loaded and non-empty)
  bool get hasDeposits {
    final UnclaimedDepositsState state = this;
    return state is UnclaimedDepositsLoaded && state.deposits.isNotEmpty;
  }

  /// Check if empty (loaded but no deposits)
  bool get isEmpty {
    final UnclaimedDepositsState state = this;
    return state is UnclaimedDepositsLoaded && state.deposits.isEmpty;
  }

  /// Get deposits if loaded, otherwise empty list
  List<DepositCardData> get depositsOrEmpty {
    final UnclaimedDepositsState state = this;
    return state is UnclaimedDepositsLoaded ? state.deposits : <DepositCardData>[];
  }

  /// Get error message if in error state, otherwise null
  String? get errorMessage {
    final UnclaimedDepositsState state = this;
    return state is UnclaimedDepositsError ? state.message : null;
  }
}

/// Initial state when first loading deposits
class UnclaimedDepositsInitial extends UnclaimedDepositsState {
  const UnclaimedDepositsInitial();
}

/// Loading state while fetching deposits from SDK
class UnclaimedDepositsLoading extends UnclaimedDepositsState {
  const UnclaimedDepositsLoading();
}

/// Success state with list of deposit card data
/// - Empty list indicates all deposits have been claimed
class UnclaimedDepositsLoaded extends UnclaimedDepositsState {
  const UnclaimedDepositsLoaded({required this.deposits});

  final List<DepositCardData> deposits;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UnclaimedDepositsLoaded && _listEquals(other.deposits, deposits);
  }

  @override
  int get hashCode => deposits.hashCode;

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Error state when fetching deposits fails
class UnclaimedDepositsError extends UnclaimedDepositsState {
  const UnclaimedDepositsError({required this.message, this.error});

  final String message;
  final Object? error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UnclaimedDepositsError && other.message == message && other.error == error;
  }

  @override
  int get hashCode => Object.hash(message, error);
}

/// Data model for DepositCard UI
class DepositCardData {
  final DepositInfo deposit;
  final bool hasError;
  final bool hasRefund;
  final String formattedTxid;
  final String? formattedErrorMessage;

  const DepositCardData({
    required this.deposit,
    required this.hasError,
    required this.hasRefund,
    required this.formattedTxid,
    this.formattedErrorMessage,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DepositCardData &&
        other.deposit == deposit &&
        other.hasError == hasError &&
        other.hasRefund == hasRefund &&
        other.formattedTxid == formattedTxid &&
        other.formattedErrorMessage == formattedErrorMessage;
  }

  @override
  int get hashCode => Object.hash(deposit, hasError, hasRefund, formattedTxid, formattedErrorMessage);
}
