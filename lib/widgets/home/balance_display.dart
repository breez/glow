import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/utils/formatters.dart';

class BalanceDisplay extends ConsumerWidget {
  const BalanceDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          _BalanceAmount(balance: balance),
          const SizedBox(height: 4),
          _BalanceLabel(),
        ],
      ),
    );
  }
}

class _BalanceAmount extends StatelessWidget {
  final AsyncValue<BigInt> balance;

  const _BalanceAmount({required this.balance});

  @override
  Widget build(BuildContext context) {
    return balance.when(
      data: (sats) => Text(
        formatSats(sats),
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w300,
          letterSpacing: -2,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
      error: (err, _) =>
          Text('Error loading', style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.error)),
    );
  }
}

class _BalanceLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'sats',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
