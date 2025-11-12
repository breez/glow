import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/logging/logger_mixin.dart';

/// Service for mnemonic generation and validation
class MnemonicService with LoggerMixin {
  /// Generate a new 12-word BIP39 mnemonic
  String generateMnemonic() {
    try {
      final String mnemonic = bip39.generateMnemonic();
      log.i('Generated new 12-word mnemonic');
      return mnemonic;
    } catch (e, stack) {
      log.e('Failed to generate mnemonic', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Validate a BIP39 mnemonic
  (bool, String?) validateMnemonic(String mnemonic) {
    try {
      final String cleaned = mnemonic.trim().toLowerCase();
      final List<String> words = cleaned.split(RegExp(r'\s+'));

      if (words.length != 12) {
        final String error = 'Must be exactly 12 words (found ${words.length})';
        log.w('Mnemonic validation failed: $error');
        return (false, error);
      }

      if (!bip39.validateMnemonic(cleaned)) {
        const String error = 'Invalid mnemonic checksum';
        log.w('Mnemonic validation failed: $error');
        return (false, error);
      }

      log.i('Mnemonic validated successfully');
      return (true, null);
    } catch (e, stack) {
      log.e('Mnemonic validation error', error: e, stackTrace: stack);
      return (false, 'Validation error: ${e.toString()}');
    }
  }

  /// Normalize a mnemonic string
  String normalizeMnemonic(String mnemonic) =>
      mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).join(' ');
}

final Provider<MnemonicService> mnemonicServiceProvider = Provider<MnemonicService>(
  (Ref ref) => MnemonicService(),
);
