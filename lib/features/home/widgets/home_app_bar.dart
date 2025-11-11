import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/core/services/wallet_storage_service.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWallet = ref.watch(activeWalletProvider);
    final hasSynced = ref.watch(hasSyncedProvider);
    final themeData = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/svg/hamburger.svg',
          height: 24.0,
          width: 24.0,
          colorFilter: ColorFilter.mode(themeData.appBarTheme.iconTheme!.color!, BlendMode.srcATop),
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      backgroundColor: Colors.transparent,
      actions: [
        _SyncIndicator(hasSynced: hasSynced),
        _UnclaimedDepositsWarning(),
        _VerificationWarning(activeWallet: activeWallet, ref: ref),
      ],
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  final bool hasSynced;

  const _SyncIndicator({required this.hasSynced});

  @override
  Widget build(BuildContext context) {
    if (hasSynced) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).appBarTheme.iconTheme!.color!),
          ),
        ),
      ),
    );
  }
}

class _UnclaimedDepositsWarning extends ConsumerWidget {
  const _UnclaimedDepositsWarning();

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
            onPressed: () => Navigator.pushNamed(context, AppRoutes.unclaimedDeposits),
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

class _VerificationWarning extends StatelessWidget {
  final AsyncValue activeWallet;
  final WidgetRef ref;

  const _VerificationWarning({required this.activeWallet, required this.ref});

  @override
  Widget build(BuildContext context) {
    return activeWallet.when(
      data: (wallet) => wallet != null && !wallet.isVerified
          ? IconButton(
              onPressed: () => _handleVerification(context, wallet),
              icon: Icon(Icons.warning_amber_rounded, color: Theme.of(context).appBarTheme.iconTheme?.color),
              tooltip: 'Verify recovery phrase',
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleVerification(BuildContext context, wallet) async {
    final mnemonic = await ref.read(walletStorageServiceProvider).loadMnemonic(wallet.id);

    if (mnemonic != null && context.mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.walletVerify,
        arguments: {'wallet': wallet, 'mnemonic': mnemonic},
      );
    }
  }
}
