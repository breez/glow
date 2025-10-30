import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/screens/debug_screen.dart';
import 'package:glow/screens/unclaimed_deposits_screen.dart';
import 'package:glow/screens/wallet/list_screen.dart';
import 'package:glow/screens/wallet/verify_screen.dart';
import 'package:glow/services/wallet_storage_service.dart';
import 'package:glow/widgets/unclaimed_deposits_icon.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWallet = ref.watch(activeWalletProvider);
    final hasSynced = ref.watch(hasSyncedProvider);

    return AppBar(
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          children: [
            const Text('Glow'),
            const SizedBox(width: 8),
            _ActiveWalletBadge(activeWallet: activeWallet),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      actions: [
        _SyncIndicator(hasSynced: hasSynced),
        _UnclaimedDepositsButton(),
        _VerificationWarning(activeWallet: activeWallet, ref: ref),
        _SettingsButton(),
      ],
    );
  }
}

class _ActiveWalletBadge extends StatelessWidget {
  final AsyncValue activeWallet;

  const _ActiveWalletBadge({required this.activeWallet});

  @override
  Widget build(BuildContext context) {
    return activeWallet.when(
      data: (wallet) => wallet != null
          ? GestureDetector(
              onTap: () => _navigateToWalletList(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(wallet.name, style: const TextStyle(fontSize: 12)),
              ),
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _navigateToWalletList(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletListScreen()));
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
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

class _UnclaimedDepositsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UnclaimedDepositsIcon(onTap: () => _navigateToUnclaimedDeposits(context));
  }

  void _navigateToUnclaimedDeposits(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UnclaimedDepositsScreen()));
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
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletVerifyScreen(wallet: wallet, mnemonic: mnemonic),
        ),
      );
    }
  }
}

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: () => _navigateToDebug(context), icon: const Icon(Icons.settings));
  }

  void _navigateToDebug(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DebugScreen()));
  }
}
