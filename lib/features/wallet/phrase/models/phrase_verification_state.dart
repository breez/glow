import 'package:equatable/equatable.dart';
import 'package:glow/core/models/wallet_metadata.dart';

/// Represents the different steps in the phrase verification flow
enum PhraseVerificationStep {
  /// Show information about the backup phrase importance
  info,

  /// Display the backup phrase for the user to write down
  display,

  /// Verify that the user has correctly written down the phrase
  verify,

  /// Backup phrase is already verified, just viewing the phrase
  complete,
}

/// Immutable state for the phrase verification flow
class PhraseVerificationState extends Equatable {
  final PhraseVerificationStep currentStep;
  final int currentPageIndex;
  final WalletMetadata wallet;
  final String mnemonic;

  const PhraseVerificationState({
    required this.currentStep,
    required this.currentPageIndex,
    required this.wallet,
    required this.mnemonic,
  });

  /// Factory constructor for initial state
  factory PhraseVerificationState.initial({required WalletMetadata wallet, required String mnemonic}) {
    // If backup phrase is already verified, go directly to complete step
    if (wallet.isVerified) {
      return PhraseVerificationState(
        currentStep: PhraseVerificationStep.complete,
        currentPageIndex: 0,
        wallet: wallet,
        mnemonic: mnemonic,
      );
    }

    // Otherwise start from the info step
    return PhraseVerificationState(
      currentStep: PhraseVerificationStep.info,
      currentPageIndex: 0,
      wallet: wallet,
      mnemonic: mnemonic,
    );
  }

  PhraseVerificationState copyWith({
    PhraseVerificationStep? currentStep,
    int? currentPageIndex,
    WalletMetadata? wallet,
    String? mnemonic,
  }) {
    return PhraseVerificationState(
      currentStep: currentStep ?? this.currentStep,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      wallet: wallet ?? this.wallet,
      mnemonic: mnemonic ?? this.mnemonic,
    );
  }

  @override
  List<Object?> get props => <Object?>[currentStep, currentPageIndex, wallet, mnemonic];
}
