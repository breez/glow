import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/widgets/transactions/providers/transaction_providers.dart';
import 'package:glow/features/home/models/home_state_factory.dart';

/// Provider for HomeStateFactory
final homeStateFactoryProvider = Provider<HomeStateFactory>((ref) {
  return HomeStateFactory(transactionFormatter: ref.watch(transactionFormatterProvider));
});
