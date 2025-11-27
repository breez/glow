import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/balance/balance_display_layout.dart';
import 'package:glow/features/balance/models/balance_state.dart';
import 'package:glow/features/balance/providers/balance_providers.dart';

/// BalanceDisplay widget - handles setup and dependency injection
/// - BalanceDisplay: handles setup
/// - BalanceDisplayLayout: pure presentation widget
class BalanceDisplay extends ConsumerWidget {
  const BalanceDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get formatted state from provider
    final BalanceState state = ref.watch(balanceStateProvider);

    // Return pure presentation widget
    return BalanceDisplayLayout(
      state: state,
      onBalanceTap: _onBalanceTap,
      onFiatBalanceTap: _onFiatBalanceTap,
    );
  }

  /// Handle tap on balance area
  void _onBalanceTap() {
    // TODO(erdemyerebasmaz): Change preferred Currency to the next one
    // (e.g., from BTC to SAT or vice versa, or hide balance)
  }

  /// Handle tap on fiat conversion area
  void _onFiatBalanceTap() {
    // TODO(erdemyerebasmaz): Change preferred Fiat Currency to the next one
    // (e.g., from USD to EUR or vice versa)
  }
}
