import 'package:flutter/material.dart';
import 'package:glow/features/wallet_phrase/models/phrase_verification_state.dart';
import 'package:glow/features/wallet_phrase/widgets/phrase_display_view.dart';
import 'package:glow/features/wallet_phrase/widgets/phrase_info_view.dart';
import 'package:glow/features/wallet_phrase/widgets/phrase_verification_container.dart';

class PhraseLayout extends StatelessWidget {
  final PhraseVerificationState state;
  final PageController pageController;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const PhraseLayout({
    required this.state,
    required this.pageController,
    required this.onNext,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // If backup phrase is already verified, show simplified view
    if (state.currentStep == PhraseVerificationStep.complete) {
      return PhraseDisplayView.viewOnly(mnemonic: state.mnemonic, onClose: onClose);
    }

    // Otherwise, show the verification flow with PageView
    return PageView(
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(), // Disable swipe, use buttons only
      children: <Widget>[
        PhraseInfoView(onNext: onNext),
        PhraseDisplayView.writeDown(mnemonic: state.mnemonic, onNext: onNext),
        PhraseVerificationContainer(wallet: state.wallet, mnemonic: state.mnemonic),
      ],
    );
  }
}
