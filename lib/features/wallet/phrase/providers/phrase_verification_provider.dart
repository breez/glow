import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet/phrase/models/phrase_verification_form_state.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('PhraseVerificationProvider');

/// Notifier for managing phrase verification state and logic
class PhraseVerificationNotifier extends Notifier<PhraseVerificationFormState> {
  late final List<String> _words;

  @override
  PhraseVerificationFormState build() {
    // This will be overridden by the autoDispose provider
    throw UnimplementedError();
  }

  void initialize(String mnemonic) {
    _words = mnemonic.split(' ');

    // Generate 3 random word indices
    final Random rand = Random();
    final Set<int> indices = <int>{};
    while (indices.length < 3) {
      indices.add(rand.nextInt(_words.length));
    }

    state = PhraseVerificationFormState(wordIndices: indices.toList()..sort());
  }

  /// Verify the provided words against the mnemonic
  Future<bool> verifyWords(List<String> providedWords, WalletMetadata wallet) async {
    state = state.copyWith(isVerifying: true);

    try {
      // Validate the words
      bool valid = true;
      for (int i = 0; i < 3; i++) {
        if (providedWords[i].trim() != _words[state.wordIndices[i]]) {
          valid = false;
          break;
        }
      }

      if (!valid) {
        state = state.copyWith(
          isVerifying: false,
          errorMessage: 'Failed to verify words. Please write down the words and try again.',
        );
        return false;
      }

      // Mark wallet as verified
      await ref.read(walletListProvider.notifier).markWalletAsVerified(wallet.id);

      state = state.copyWith(isVerifying: false);
      log.i('Backup phrase verified successfully for wallet: ${wallet.id}');
      return true;
    } catch (e, stack) {
      log.e('Failed to verify backup phrase', error: e, stackTrace: stack);
      state = state.copyWith(
        isVerifying: false,
        errorMessage: 'Failed to verify backup phrase: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith();
  }
}

/// Provider for phrase verification
/// Uses autoDispose since this is screen-scoped
final NotifierProvider<PhraseVerificationNotifier, PhraseVerificationFormState>
phraseVerificationProvider =
    NotifierProvider.autoDispose<PhraseVerificationNotifier, PhraseVerificationFormState>(
      PhraseVerificationNotifier.new,
    );
