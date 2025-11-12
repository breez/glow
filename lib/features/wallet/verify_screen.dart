import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/logging/logger_mixin.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/features/wallet/widgets/recovery_phrase_grid.dart';
import 'package:glow/features/wallet/widgets/security_tips_card.dart';
import 'package:glow/features/wallet/widgets/warning_card.dart';

class WalletVerifyScreen extends ConsumerStatefulWidget {
  final WalletMetadata wallet;
  final String mnemonic;

  const WalletVerifyScreen({required this.wallet, required this.mnemonic, super.key});

  @override
  ConsumerState<WalletVerifyScreen> createState() => _WalletVerifyScreenState();
}

class _WalletVerifyScreenState extends ConsumerState<WalletVerifyScreen> with LoggerMixin {
  bool _isConfirming = false;

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);

    try {
      await ref.read(walletListProvider.notifier).markWalletAsVerified(widget.wallet.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery phrase verified!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      log.e('Failed to verify wallet', error: e);
      setState(() => _isConfirming = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Recovery Phrase')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const WarningCard(
            title: 'Write This Down!',
            message:
                'Please confirm that you have written down your recovery phrase. '
                'This is essential for recovering your wallet if you lose access to your device.',
          ),
          const SizedBox(height: 24),
          RecoveryPhraseGrid(mnemonic: widget.mnemonic),
          const SizedBox(height: 24),
          const SecurityTipsCard(),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isConfirming ? null : _confirm,
            child: _isConfirming
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('I Have Written It Down'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }
}
