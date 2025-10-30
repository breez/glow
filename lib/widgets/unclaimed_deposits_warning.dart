import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';

class UnclaimedDepositsWarning extends ConsumerWidget {
  final VoidCallback? onTap;

  const UnclaimedDepositsWarning({this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnclaimedAsync = ref.watch(hasUnclaimedDepositsProvider);
    final countAsync = ref.watch(unclaimedDepositsCountProvider);

    return hasUnclaimedAsync.when(
      data: (hasUnclaimed) {
        if (!hasUnclaimed) return const SizedBox.shrink();

        return countAsync.when(
          data: (count) => _buildBanner(context, count),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, int count) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count pending deposit${count > 1 ? 's' : ''} need${count == 1 ? 's' : ''} attention',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onErrorContainer.withValues(alpha: .7),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
