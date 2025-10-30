import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';

class UnclaimedDepositsIcon extends ConsumerWidget {
  final VoidCallback? onTap;

  const UnclaimedDepositsIcon({this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnclaimedAsync = ref.watch(hasUnclaimedDepositsProvider);
    final countAsync = ref.watch(unclaimedDepositsCountProvider);

    return hasUnclaimedAsync.when(
      data: (hasUnclaimed) {
        if (!hasUnclaimed) return const SizedBox.shrink();

        return countAsync.when(
          data: (count) => IconButton(
            icon: Badge(label: Text(count.toString()), child: const Icon(Icons.warning_amber_rounded)),
            onPressed: onTap,
            tooltip: 'Pending deposits',
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
