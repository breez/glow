import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/models/wallet_metadata.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/widgets/wallet/recovery_phrase_grid.dart';
import 'package:glow/widgets/wallet/security_tips_card.dart';
import 'package:glow/widgets/wallet/warning_card.dart';

class WalletVerifyScreen extends ConsumerStatefulWidget {
  final WalletMetadata wallet;
  final String mnemonic;

  const WalletVerifyScreen({super.key, required this.wallet, required this.mnemonic});

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recovery phrase verified!'), backgroundColor: Colors.green));
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
      appBar: AppBar(title: Text('Verify Recovery Phrase')),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          WarningCard(
            title: 'Write This Down!',
            message:
                'Please confirm that you have written down your recovery phrase. '
                'This is essential for recovering your wallet if you lose access to your device.',
          ),
          SizedBox(height: 24),
          RecoveryPhraseGrid(mnemonic: widget.mnemonic, showCopyButton: true),
          SizedBox(height: 24),
          SecurityTipsCard(),
          SizedBox(height: 32),
          FilledButton(
            onPressed: _isConfirming ? null : _confirm,
            child: _isConfirming
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('I Have Written It Down'),
          ),
          SizedBox(height: 16),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ],
      ),
    );
  }
}
