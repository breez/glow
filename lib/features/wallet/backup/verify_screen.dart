import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/features/wallet/backup/backup_phrase_info_screen.dart';
import 'package:glow/features/wallet/backup/phrase_grid_screen.dart';
import 'package:glow/features/wallet/backup/phrase_verification_screen.dart';
import 'package:glow/features/wallet/widgets/backup_phrase_grid.dart';
import 'package:glow/features/widgets/bottom_nav_button.dart';

class WalletVerifyScreen extends ConsumerStatefulWidget {
  final WalletMetadata wallet;
  final String mnemonic;

  const WalletVerifyScreen({required this.wallet, required this.mnemonic, super.key});

  @override
  ConsumerState<WalletVerifyScreen> createState() => _WalletVerifyScreenState();
}

class _WalletVerifyScreenState extends ConsumerState<WalletVerifyScreen> {
  int _step = 0;

  void _nextStep() {
    setState(() {
      _step++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO(erdemyerebasmaz): Extract steps into a proper state machine or PageView for better maintainability
    // If wallet is already verified, just show the backup phrase with close button
    if (widget.wallet.isVerified) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your backup phrase'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(children: <Widget>[BackupPhraseGrid(mnemonic: widget.mnemonic)]),
        ),
        bottomNavigationBar: BottomNavButton(text: 'CLOSE', onPressed: () => Navigator.of(context).pop()),
      );
    }

    // Otherwise, go through the verification flow
    if (_step == 0) {
      return BackupPhraseInfoScreen(onNext: _nextStep);
    } else if (_step == 1) {
      return PhraseGridScreen(mnemonic: widget.mnemonic, onNext: _nextStep);
    } else {
      return PhraseVerificationScreen(wallet: widget.wallet, mnemonic: widget.mnemonic);
    }
  }
}
