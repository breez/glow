import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/widgets/lightning_receive_view.dart';
import 'package:glow/features/receive/widgets/bitcoin_receive_view.dart';

class ReceiveViewSwitcher extends ConsumerWidget {
  final ReceiveState state;

  const ReceiveViewSwitcher({required this.state, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(child: Text(state.error ?? 'Unknown error'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: switch (state.method) {
        ReceiveMethod.lightning => const LightningReceiveView(),
        ReceiveMethod.bitcoin => const BitcoinReceiveView(),
      },
    );
  }
}
