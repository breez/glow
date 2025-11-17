import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/features/wallet/backup_phrase_info_screen.dart';
import 'package:glow/features/wallet/phrase_grid_screen.dart';
import 'package:glow/features/wallet/phrase_verification_screen.dart';

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
    if (_step == 0) {
      return BackupPhraseInfoScreen(onNext: _nextStep);
    } else if (_step == 1) {
      return PhraseGridScreen(mnemonic: widget.mnemonic, onNext: _nextStep);
    } else {
      return PhraseVerificationScreen(wallet: widget.wallet, mnemonic: widget.mnemonic);
    }
  }
}
