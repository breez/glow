import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/models/wallet_metadata.dart';

/// Manages secure storage of wallet metadata and mnemonics.
class WalletStorageService with LoggerMixin {
  /// Storage Keys:
  /// - `wallet_list`: JSON array of wallet metadata
  /// - `active_wallet_id`: ID of currently active wallet
  /// - `wallet_mnemonic_{id}`: Encrypted mnemonic for wallet {id}
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

      final wallets = (jsonDecode(json) as List).map((e) => WalletMetadata.fromJson(e)).toList();
      if (wallets.isEmpty) {
        log.d('Wallet list is empty after decoding');
        return [];
      }
      return wallets;
    } catch (e, stack) {
      log.e('Failed to load wallets', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Save wallet list to secure storage
  Future<void> saveWallets(List<WalletMetadata> wallets) async {
    try {
      await _storage.write(key: _walletListKey, value: jsonEncode(wallets.map((w) => w.toJson()).toList()));
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
      await _saveMnemonic(wallet.id, mnemonic);
      final wallets = await loadWallets();
      await saveWallets([...wallets, wallet]);
      log.i('Added wallet: ${wallet.id} (${wallet.name})');
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
      if (index == -1) throw Exception('Wallet not found: ${wallet.id}');

      await saveWallets([...wallets]..[index] = wallet);
      log.i('Updated wallet: ${wallet.id}');
    } catch (e, stack) {
      log.e('Failed to update wallet: ${wallet.id}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Delete a wallet and its mnemonic
  Future<void> deleteWallet(String walletId) async {
    try {
      await _deleteMnemonic(walletId);
      final wallets = await loadWallets();
      await saveWallets(wallets.where((w) => w.id != walletId).toList());

      if (await getActiveWalletId() == walletId) {
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
  Future<String?> getActiveWalletId() async {
    try {
      final id = await _storage.read(key: _activeWalletKey);
      if (id == null) {
        log.d('No active wallet set');
      }
      return id;
    } catch (e, stack) {
      log.e('Failed to get active wallet ID', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Set the currently active wallet
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
  // Mnemonic Management
  // ============================================================================

  /// Load mnemonic for a specific wallet
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
  Future<void> _deleteMnemonic(String walletId) async {
    try {
      await _storage.delete(key: '$_mnemonicPrefix$walletId');
      log.d('Deleted mnemonic for wallet: $walletId');
    } catch (e) {
      // SECURITY: Do NOT log the error details as they might contain mnemonic
      log.e('Failed to delete mnemonic for wallet: $walletId (details hidden for security)');
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
  static String generateWalletId(String mnemonic) =>
      sha256.convert(utf8.encode(mnemonic)).toString().substring(0, 8);
}

final walletStorageServiceProvider = Provider<WalletStorageService>((ref) {
  return WalletStorageService();
});
