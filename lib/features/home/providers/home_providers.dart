import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/transaction_formatter.dart';

/// Provider for TransactionFormatter service (re-exported for convenience)
final Provider<TransactionFormatter> transactionFormatterProvider = Provider<TransactionFormatter>((
  Ref ref,
) {
  return const TransactionFormatter();
});
