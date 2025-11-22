import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/phrase/models/phrase_verification_state.dart';
import 'package:glow/features/wallet/phrase/phrase_layout.dart';

class PhraseScreen extends ConsumerStatefulWidget {
  final WalletMetadata wallet;
  final String mnemonic;

  const PhraseScreen({required this.wallet, required this.mnemonic, super.key});

  @override
  ConsumerState<PhraseScreen> createState() => _PhraseScreenState();
}

class _PhraseScreenState extends ConsumerState<PhraseScreen> {
  late final PageController _pageController;
  late PhraseVerificationState _state;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _state = PhraseVerificationState.initial(wallet: widget.wallet, mnemonic: widget.mnemonic);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final PhraseVerificationStep currentStep = _state.currentStep;

    setState(() {
      switch (currentStep) {
        case PhraseVerificationStep.info:
          _state = _state.copyWith(currentStep: PhraseVerificationStep.display, currentPageIndex: 1);
          break;
        case PhraseVerificationStep.display:
          _state = _state.copyWith(currentStep: PhraseVerificationStep.verify, currentPageIndex: 2);
          break;
        case PhraseVerificationStep.verify:
        case PhraseVerificationStep.complete:
          // No next step from verify or complete
          break;
      }
    });

    // Animate to the new page
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _state.currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhraseLayout(
      state: _state,
      pageController: _pageController,
      onNext: _nextStep,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
