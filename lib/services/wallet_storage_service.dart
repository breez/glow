import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/models/wallet_metadata.dart';

/// Manages secure storage of wallet metadata and mnemonics.
///
/// SECURITY CRITICAL: All mnemonic storage is encrypted at rest using
/// flutter_secure_storage which leverages platform-specific secure storage:
/// - Android: EncryptedSharedPreferences (AES encryption)
/// - iOS: Keychain
///
/// Storage Keys:
/// - `wallet_list`: JSON array of wallet metadata
/// - `active_wallet_id`: ID of currently active wallet
/// - `wallet_mnemonic_{id}`: Encrypted mnemonic for wallet {id}
///
/// Security Notes:
/// - Mnemonics are NEVER logged
/// - Mnemonics are stored separately from metadata
/// - Each mnemonic is keyed by wallet ID for isolation
/// - All read/write operations are async to avoid blocking UI
class WalletStorageService with LoggerMixin {
  static const _walletListKey = 'wallet_list';
  static const _activeWalletKey = 'active_wallet_id';
  static const _mnemonicPrefix = 'wallet_mnemonic_';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ============================================================================
  // Wallet List Management
  // ============================================================================

  /// Load all wallets from secure storage
  ///
  /// Returns empty list if no wallets exist or on error
  Future<List<WalletMetadata>> loadWallets() async {
    try {
      final json = await _storage.read(key: _walletListKey);
      if (json == null || json.isEmpty) {
        log.d('No wallets found in storage');
        return [];
      }

      final List<dynamic> list = jsonDecode(json);
      final wallets = list.map((e) => WalletMetadata.fromJson(e as Map<String, dynamic>)).toList();

      log.i('Loaded ${wallets.length} wallets from storage');
      return wallets;
    } catch (e, stack) {
      log.e('Failed to load wallets', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Save wallet list to secure storage
  ///
  /// This overwrites the entire wallet list
  Future<void> saveWallets(List<WalletMetadata> wallets) async {
    try {
      final json = jsonEncode(wallets.map((w) => w.toJson()).toList());
      await _storage.write(key: _walletListKey, value: json);
      log.i('Saved ${wallets.length} wallets to storage');
    } catch (e, stack) {
      log.e('Failed to save wallets', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Add a new wallet to storage
  ///
  /// SECURITY: Also stores the mnemonic encrypted separately
  Future<void> addWallet(WalletMetadata wallet, String mnemonic) async {
    try {
      // Store mnemonic separately (SECURITY CRITICAL)
      await _saveMnemonic(wallet.id, mnemonic);

      // Add to wallet list
      final wallets = await loadWallets();
      wallets.add(wallet);
      await saveWallets(wallets);

      log.i('Added wallet: ${wallet.id} (${wallet.name}) on ${wallet.network}');
    } catch (e, stack) {
      log.e('Failed to add wallet: ${wallet.id}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Update an existing wallet's metadata
  ///
  /// Does NOT update mnemonic (mnemonics are immutable)
  Future<void> updateWallet(WalletMetadata wallet) async {
    try {
      final wallets = await loadWallets();
      final index = wallets.indexWhere((w) => w.id == wallet.id);

      if (index == -1) {
        throw Exception('Wallet not found: ${wallet.id}');
      }

      wallets[index] = wallet;
      await saveWallets(wallets);

      log.i('Updated wallet: ${wallet.id}');
    } catch (e, stack) {
      log.e('Failed to update wallet: ${wallet.id}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Delete a wallet and its mnemonic
  ///
  /// SECURITY: Ensures mnemonic is also deleted
  Future<void> deleteWallet(String walletId) async {
    try {
      // Delete mnemonic first (SECURITY CRITICAL)
      await _deleteMnemonic(walletId);

      // Remove from wallet list
      final wallets = await loadWallets();
      wallets.removeWhere((w) => w.id == walletId);
      await saveWallets(wallets);

      // Clear active wallet if it was deleted
      final activeId = await getActiveWalletId();
      if (activeId == walletId) {
        await _storage.delete(key: _activeWalletKey);
        log.i('Cleared active wallet reference');
      }

      log.i('Deleted wallet: $walletId');
    } catch (e, stack) {
      log.e('Failed to delete wallet: $walletId', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ============================================================================
  // Active Wallet Management
  // ============================================================================

  /// Get the ID of the currently active wallet
  ///
  /// Returns null if no active wallet is set
  Future<String?> getActiveWalletId() async {
    try {
      final id = await _storage.read(key: _activeWalletKey);
      if (id != null) {
        log.d('Active wallet ID: $id');
      } else {
        log.d('No active wallet set');
      }
      return id;
    } catch (e, stack) {
      log.e('Failed to get active wallet ID', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Set the currently active wallet
  ///
  /// This is used to remember which wallet to load on app start
  Future<void> setActiveWalletId(String walletId) async {
    try {
      await _storage.write(key: _activeWalletKey, value: walletId);
      log.i('Set active wallet: $walletId');
    } catch (e, stack) {
      log.e('Failed to set active wallet: $walletId', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Clear the active wallet reference
  Future<void> clearActiveWallet() async {
    try {
      await _storage.delete(key: _activeWalletKey);
      log.i('Cleared active wallet');
    } catch (e, stack) {
      log.e('Failed to clear active wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ============================================================================
  // Mnemonic Management (SECURITY CRITICAL)
  // ============================================================================

  /// Load mnemonic for a specific wallet
  ///
  /// SECURITY: Never logs the mnemonic content
  /// Returns null if mnemonic not found (should not happen in normal flow)
  Future<String?> loadMnemonic(String walletId) async {
    try {
      final mnemonic = await _storage.read(key: '$_mnemonicPrefix$walletId');
      if (mnemonic != null) {
        log.d('Loaded mnemonic for wallet: $walletId');
      } else {
        log.w('Mnemonic not found for wallet: $walletId');
      }
      return mnemonic;
    } catch (e) {
      // SECURITY: Do NOT log the error details as they might contain mnemonic
      log.e('Failed to load mnemonic for wallet: $walletId (details hidden for security)');
      return null;
    }
  }

  /// Save mnemonic for a specific wallet
  ///
  /// SECURITY: Never logs the mnemonic content
  Future<void> _saveMnemonic(String walletId, String mnemonic) async {
    try {
      await _storage.write(key: '$_mnemonicPrefix$walletId', value: mnemonic);
      log.d('Saved mnemonic for wallet: $walletId (content not logged)');
    } catch (e) {
      // SECURITY: Do NOT log the error details as they might contain mnemonic
      log.e('Failed to save mnemonic for wallet: $walletId (details hidden for security)');
      rethrow;
    }
  }

  /// Delete mnemonic for a specific wallet
  ///
  /// SECURITY: Ensures mnemonic is removed from secure storage
  Future<void> _deleteMnemonic(String walletId) async {
    try {
      await _storage.delete(key: '$_mnemonicPrefix$walletId');
      log.d('Deleted mnemonic for wallet: $walletId');
    } catch (e, stack) {
      log.e('Failed to delete mnemonic for wallet: $walletId', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ============================================================================
  // Utilities
  // ============================================================================

  /// Generate a unique wallet ID from mnemonic
  ///
  /// Uses first 8 characters of SHA-256 hash of the mnemonic
  /// This provides a deterministic ID that's unique per mnemonic
  ///
  /// SECURITY: The ID doesn't reveal the mnemonic, but allows
  /// verification that two mnemonics are the same
  static String generateWalletId(String mnemonic) {
    final bytes = utf8.encode(mnemonic);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8);
  }

  /// Clear all wallet data (for debugging/testing only)
  ///
  /// DANGER: This deletes everything including all mnemonics
  /// Should only be used in development or for reset functionality
  Future<void> clearAllData() async {
    try {
      log.w('CLEARING ALL WALLET DATA - This cannot be undone!');
      await _storage.deleteAll();
      log.i('All wallet data cleared');
    } catch (e, stack) {
      log.e('Failed to clear all data', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
