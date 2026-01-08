import 'dart:math';

import 'package:flutter/material.dart';
import 'package:glow/features/balance/models/balance_state.dart';
import 'package:glow/features/balance/widgets/balance_display_shimmer.dart';

/// Pure presentation widget for balance display
class BalanceDisplayLayout extends StatelessWidget {
  const BalanceDisplayLayout({
    required this.state,
    super.key,
    this.onBalanceTap,
    this.onFiatBalanceTap,
    this.scrollOffsetFactor = 0.0,
  });

  final BalanceState state;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onFiatBalanceTap;
  final double scrollOffsetFactor;

  @override
  Widget build(BuildContext context) {
    return switch ((state.isLoading, state.hasError)) {
      (true, _) => const _BalanceLoadingView(),
      (_, true) => _BalanceErrorView(error: state.error),
      _ => _BalanceContentView(
        state: state,
        onBalanceTap: onBalanceTap,
        onFiatBalanceTap: onFiatBalanceTap,
        scrollOffsetFactor: scrollOffsetFactor,
      ),
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
  const _BalanceContentView({
    required this.state,
    this.onBalanceTap,
    this.onFiatBalanceTap,
    this.scrollOffsetFactor = 0.0,
  });
  final BalanceState state;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onFiatBalanceTap;
  final double scrollOffsetFactor;

  // Position animation constants
  static const double _balanceTopPosition = 60.0;
  static const double _fiatTopPosition = 100.0;
  static const double _offsetTransition = 60.0;

  // Font size animation ranges
  static const double _balanceFontSizeStart = 28.0;
  static const double _balanceFontSizeEnd = 20.0;
  static const double _labelFontSizeStart = 22.0;
  static const double _labelFontSizeEnd = 16.0;

  static double _interpolateFontSize(double startSize, double endSize, double factor) =>
      startSize - (startSize - endSize) * factor;

  static double _calculateAlpha(double factor) => pow(1.0 - factor, 2).toDouble();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final double alpha = _calculateAlpha(scrollOffsetFactor);
    final double balanceFontSize = _interpolateFontSize(
      _balanceFontSizeStart,
      _balanceFontSizeEnd,
      scrollOffsetFactor,
    );
    final double labelFontSize = _interpolateFontSize(
      _labelFontSizeStart,
      _labelFontSizeEnd,
      scrollOffsetFactor,
    );

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          top: _balanceTopPosition - _offsetTransition * scrollOffsetFactor,
          child: TextButton(
            onPressed: onBalanceTap,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: balanceFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.56,
                ),
                text: state.formattedBalance,
                children: <InlineSpan>[
                  TextSpan(
                    text: ' sats',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.52,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.formattedFiat != null)
          Positioned(
            top: _fiatTopPosition - _offsetTransition * scrollOffsetFactor,
            child: TextButton(
              onPressed: onFiatBalanceTap,
              child: Text(
                state.formattedFiat!,
                style: TextStyle(
                  fontSize: 16.0,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w500,
                  height: 1.24,
                  color: theme.colorScheme.onSurface.withValues(alpha: alpha),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
