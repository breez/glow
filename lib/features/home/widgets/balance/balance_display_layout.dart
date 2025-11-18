import 'package:flutter/material.dart';
import 'package:glow/features/home/widgets/balance/theme/balance_text_styles.dart';
import 'package:glow/features/home/widgets/balance/widgets/balance_display_shimmer.dart';
import 'package:glow/features/home/widgets/balance/models/balance_state.dart';

/// Pure presentation widget for balance display
class BalanceDisplayLayout extends StatelessWidget {
  const BalanceDisplayLayout({required this.state, super.key, this.onBalanceTap, this.onFiatBalanceTap});

  final BalanceState state;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onFiatBalanceTap;

  @override
  Widget build(BuildContext context) {
    return switch ((state.isLoading, state.hasError)) {
      (true, _) => const _BalanceLoadingView(),
      (_, true) => _BalanceErrorView(error: state.error),
      _ => _BalanceContentView(state: state, onBalanceTap: onBalanceTap, onFiatBalanceTap: onFiatBalanceTap),
    };
  }
}

class _BalanceLoadingView extends StatelessWidget {
  const _BalanceLoadingView();

  @override
  Widget build(BuildContext context) {
    return const BalanceDisplayShimmer();
  }
}

class _BalanceErrorView extends StatelessWidget {
  const _BalanceErrorView({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: <Widget>[
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            error ?? 'Error loading balance',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}

class _BalanceContentView extends StatelessWidget {
  const _BalanceContentView({required this.state, this.onBalanceTap, this.onFiatBalanceTap});
  final BalanceState state;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onFiatBalanceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextButton(
          onPressed: onBalanceTap,
          child: RichText(
            text: TextSpan(
              style: BalanceTextStyles.amount,
              text: state.formattedBalance,
              children: <InlineSpan>[const TextSpan(text: ' sats', style: BalanceTextStyles.unit)],
            ),
          ),
        ),
        if (state.formattedFiat != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(state.formattedFiat!, style: BalanceTextStyles.fiatAmount),
        ],
      ],
    );
  }
}
