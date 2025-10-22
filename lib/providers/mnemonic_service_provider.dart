import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:glow_breez/models/wordslist.dart';

/// Service for mnemonic generation and validation
///
/// Uses bip39 package for:
/// - Generating cryptographically secure 12-word mnemonics
/// - Validating mnemonic checksums
/// - Enforcing 12-word requirement (128-bit entropy)
///
/// SECURITY NOTES:
/// - Always use 12 words (128-bit entropy = ~2^128 combinations)
/// - Never generate mnemonics client-side in production without secure RNG
/// - bip39 package uses dart:math.Random.secure() for entropy
/// - Mnemonics MUST be validated before use to prevent typos
class MnemonicService {
  final _log = AppLogger.getLogger('MnemonicService');

  /// Generate a new 12-word BIP39 mnemonic
  ///
  /// Returns a space-separated string of 12 words from the BIP39 wordlist
  ///
  /// Example: "witch collapse practice feed shame open despair creek road again ice least"
  ///
  /// SECURITY: Uses cryptographically secure random number generator
  String generateMnemonic() {
    try {
      // Generate 128-bit entropy (12 words)
      final mnemonic = bip39.generateMnemonic(strength: 128);

      _log.i('Generated new 12-word mnemonic');
      return mnemonic;
    } catch (e, stack) {
      _log.e('Failed to generate mnemonic', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Validate a BIP39 mnemonic
  ///
  /// Checks:
  /// 1. Exactly 12 words
  /// 2. All words are in BIP39 wordlist
  /// 3. Checksum is valid
  ///
  /// Returns (isValid, errorMessage)
  /// - If valid: (true, null)
  /// - If invalid: (false, "Error description")
  (bool, String?) validateMnemonic(String mnemonic) {
    try {
      // Clean up input
      final cleaned = mnemonic.trim().toLowerCase();
      final words = cleaned.split(RegExp(r'\s+'));

      // Check word count
      if (words.length != 12) {
        final error = 'Must be exactly 12 words (found ${words.length})';
        _log.w('Mnemonic validation failed: $error');
        return (false, error);
      }

      // Check if all words are valid BIP39 words
      for (final word in words) {
        if (!bip39.validateMnemonic(word)) {
          // Try to validate entire mnemonic to get better error
          if (!bip39.validateMnemonic(cleaned)) {
            final error = 'Invalid word or checksum: "$word"';
            _log.w('Mnemonic validation failed: $error');
            return (false, error);
          }
        }
      }

      // Validate entire mnemonic (includes checksum verification)
      if (!bip39.validateMnemonic(cleaned)) {
        const error = 'Invalid mnemonic checksum';
        _log.w('Mnemonic validation failed: $error');
        return (false, error);
      }

      _log.i('Mnemonic validated successfully');
      return (true, null);
    } catch (e, stack) {
      _log.e('Mnemonic validation error', error: e, stackTrace: stack);
      return (false, 'Validation error: ${e.toString()}');
    }
  }

  /// Normalize a mnemonic string
  ///
  /// - Trims whitespace
  /// - Converts to lowercase
  /// - Collapses multiple spaces to single space
  /// - Removes leading/trailing spaces from each word
  ///
  /// This helps handle user input that might have formatting issues
  String normalizeMnemonic(String mnemonic) {
    return mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).join(' ');
  }

  /// Check if a string looks like it might be a mnemonic
  ///
  /// Quick check before full validation (doesn't validate checksum)
  /// Returns true if:
  /// - Has 12 words
  /// - All words are alphabetic
  bool looksLikeMnemonic(String input) {
    final words = input.trim().split(RegExp(r'\s+'));
    if (words.length != 12) return false;

    // Check if all words are alphabetic (no numbers/symbols)
    return words.every((word) => RegExp(r'^[a-zA-Z]+$').hasMatch(word));
  }

  /// Get the BIP39 wordlist for autocomplete/validation UI
  ///
  /// Returns all 2048 words in the English BIP39 wordlist
  List<String> getWordlist() {
    return WORDLIST;
  }

  /// Find similar words in wordlist (for typo suggestions)
  ///
  /// Given a word, returns similar words from the BIP39 wordlist
  /// Useful for suggesting corrections when user makes typos
  List<String> findSimilarWords(String word, {int maxResults = 5}) {
    if (word.isEmpty) return [];

    final cleaned = word.toLowerCase();
    final wordlist = WORDLIST;

    // Find words that start with the input
    final matches = wordlist.where((w) => w.startsWith(cleaned)).take(maxResults).toList();

    return matches;
  }
}

/// Provider for MnemonicService
///
/// Single instance shared across the app
/// Usage: `ref.read(mnemonicServiceProvider).generateMnemonic()`
final mnemonicServiceProvider = Provider<MnemonicService>((ref) {
  return MnemonicService();
});
