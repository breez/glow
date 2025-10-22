import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/models/wallet_metadata.dart';
import 'package:glow_breez/providers/mnemonic_service_provider.dart';
import 'package:glow_breez/services/wallet_storage_service.dart';

// ============================================================================
// Wallet Storage Service Provider
// ============================================================================

/// Single instance of WalletStorageService
final walletStorageServiceProvider = Provider<WalletStorageService>((ref) {
  return WalletStorageService();
});

// ============================================================================
// Wallet List Management
// ============================================================================

/// Provider for the list of all wallets
///
/// Loads from secure storage on first access
/// Automatically refreshes when wallets are added/removed
class WalletListNotifier extends AsyncNotifier<List<WalletMetadata>> with LoggerMixin {
  @override
  Future<List<WalletMetadata>> build() async {
    log.i('Loading wallet list from storage');
    final storage = ref.read(walletStorageServiceProvider);
    final wallets = await storage.loadWallets();
    log.i('Loaded ${wallets.length} wallets');
    return wallets;
  }

  /// Create a new wallet with generated mnemonic
  ///
  /// Steps:
  /// 1. Generate new 12-word mnemonic
  /// 2. Create wallet metadata
  /// 3. Save to secure storage
  /// 4. Add to wallet list
  /// 5. Return (wallet, mnemonic) for backup flow
  Future<(WalletMetadata, String)> createWallet({required String name, required Network network}) async {
    if (name.trim().isEmpty) {
      throw Exception('Wallet name cannot be empty');
    }

    try {
      log.i('Creating new wallet: $name on ${network.name}');

      final mnemonicService = ref.read(mnemonicServiceProvider);
      final mnemonic = mnemonicService.generateMnemonic();

      final walletId = WalletStorageService.generateWalletId(mnemonic);
      final wallet = WalletMetadata(
        id: walletId,
        name: name,
        network: network.name,
        createdAt: DateTime.now(),
        isBackedUp: false,
      );

      final storage = ref.read(walletStorageServiceProvider);
      await storage.addWallet(wallet, mnemonic);

      state = AsyncValue.data([...state.value ?? [], wallet]);

      log.i('Created wallet: $walletId ($name)');
      return (wallet, mnemonic);
    } catch (e, stack) {
      log.e('Failed to create wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Import an existing wallet from mnemonic
  ///
  /// Steps:
  /// 1. Validate mnemonic
  /// 2. Check if wallet already exists (by ID)
  /// 3. Create wallet metadata
  /// 4. Save to secure storage
  /// 5. Add to wallet list
  Future<WalletMetadata> importWallet({
    required String name,
    required String mnemonic,
    required Network network,
  }) async {
    try {
      log.i('Importing wallet: $name on ${network.name}');

      // Validate mnemonic
      final mnemonicService = ref.read(mnemonicServiceProvider);
      final normalized = mnemonicService.normalizeMnemonic(mnemonic);
      final (isValid, error) = mnemonicService.validateMnemonic(normalized);

      if (!isValid) {
        log.w('Invalid mnemonic: $error');
        throw Exception('Invalid mnemonic: $error');
      }

      // Check if wallet already exists
      final walletId = WalletStorageService.generateWalletId(normalized);
      final existingWallets = state.value ?? [];

      if (existingWallets.any((w) => w.id == walletId)) {
        log.w('Wallet already exists: $walletId');
        throw Exception('This wallet already exists');
      }

      // Create wallet metadata
      final wallet = WalletMetadata(
        id: walletId,
        name: name,
        network: network.name,
        createdAt: DateTime.now(),
        isBackedUp: true, // Imported wallet is already backed up
      );

      // Save to storage
      final storage = ref.read(walletStorageServiceProvider);
      await storage.addWallet(wallet, normalized);

      // Update state
      state = AsyncValue.data([...existingWallets, wallet]);

      log.i('Imported wallet: $walletId ($name)');
      return wallet;
    } catch (e, stack) {
      log.e('Failed to import wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Mark wallet as backed up
  ///
  /// Called after user completes backup verification
  Future<void> markAsBackedUp(String walletId) async {
    try {
      log.i('Marking wallet as backed up: $walletId');

      final wallets = state.value ?? [];
      final index = wallets.indexWhere((w) => w.id == walletId);

      if (index == -1) {
        throw Exception('Wallet not found: $walletId');
      }

      final updated = wallets[index].copyWith(isBackedUp: true);
      final storage = ref.read(walletStorageServiceProvider);
      await storage.updateWallet(updated);

      // Update state
      final newWallets = [...wallets];
      newWallets[index] = updated;
      state = AsyncValue.data(newWallets);

      log.i('Wallet marked as backed up: $walletId');
    } catch (e, stack) {
      log.e('Failed to mark wallet as backed up', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Update wallet name
  Future<void> updateWalletName(String walletId, String newName) async {
    try {
      log.i('Updating wallet name: $walletId -> $newName');

      final wallets = state.value ?? [];
      final index = wallets.indexWhere((w) => w.id == walletId);

      if (index == -1) {
        throw Exception('Wallet not found: $walletId');
      }

      final updated = wallets[index].copyWith(name: newName);
      final storage = ref.read(walletStorageServiceProvider);
      await storage.updateWallet(updated);

      // Update state
      final newWallets = [...wallets];
      newWallets[index] = updated;
      state = AsyncValue.data(newWallets);

      log.i('Wallet name updated: $walletId');
    } catch (e, stack) {
      log.e('Failed to update wallet name', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Delete a wallet
  ///
  /// DANGER: This permanently deletes the wallet and its mnemonic
  /// Make sure user has backed up mnemonic before calling this
  Future<void> deleteWallet(String walletId) async {
    try {
      log.w('Deleting wallet: $walletId');

      final storage = ref.read(walletStorageServiceProvider);
      await storage.deleteWallet(walletId);

      // Update state
      final wallets = state.value ?? [];
      state = AsyncValue.data(wallets.where((w) => w.id != walletId).toList());

      log.i('Wallet deleted: $walletId');
    } catch (e, stack) {
      log.e('Failed to delete wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Refresh wallet list from storage
  Future<void> refresh() async {
    log.d('Refreshing wallet list');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(walletStorageServiceProvider);
      return await storage.loadWallets();
    });
  }
}

final walletListProvider = AsyncNotifierProvider<WalletListNotifier, List<WalletMetadata>>(
  WalletListNotifier.new,
);

// ============================================================================
// Active Wallet Management
// ============================================================================

/// Provider for the currently active wallet
///
/// Manages:
/// - Which wallet is currently loaded
/// - Persistence of active wallet selection
/// - Wallet switching with SDK disconnect/reconnect
///
/// Note: This provider automatically stays in sync with walletListProvider,
/// so when a wallet is renamed, the active wallet will reflect the new name.
class ActiveWalletNotifier extends AsyncNotifier<WalletMetadata?> with LoggerMixin {
  String? _activeWalletId;

  @override
  Future<WalletMetadata?> build() async {
    log.i('Loading active wallet');

    // Get active wallet ID from storage (only once)
    if (_activeWalletId == null) {
      final storage = ref.read(walletStorageServiceProvider);
      _activeWalletId = await storage.getActiveWalletId();
    }

    if (_activeWalletId == null) {
      log.i('No active wallet set');
      return null;
    }

    // Always get the latest wallet data from walletListProvider
    // This ensures we always have the most up-to-date name, etc.
    final wallets = await ref.watch(walletListProvider.future);
    final wallet = wallets.where((w) => w.id == _activeWalletId).firstOrNull;

    if (wallet != null) {
      log.i('Active wallet: ${wallet.id} (${wallet.name})');
      return wallet;
    } else {
      log.w('Active wallet not found in list: $_activeWalletId');
      final storage = ref.read(walletStorageServiceProvider);
      await storage.clearActiveWallet();
      _activeWalletId = null;
      return null;
    }
  }

  /// Switch to a different wallet
  ///
  /// CRITICAL SDK LIFECYCLE:
  /// 1. Disconnect current SDK instance
  /// 2. Update active wallet ID in storage
  /// 3. Update state (triggers SDK reconnection via sdkProvider)
  ///
  /// The sdkProvider watches activeWalletProvider and will automatically
  /// reconnect with the new wallet's mnemonic and storage directory
  Future<void> switchWallet(String walletId) async {
    try {
      log.i('Switching to wallet: $walletId');

      // Get wallet from list
      final wallets = await ref.read(walletListProvider.future);
      final wallet = wallets.where((w) => w.id == walletId).firstOrNull;

      if (wallet == null) {
        throw Exception('Wallet not found: $walletId');
      }

      // Update storage
      final storage = ref.read(walletStorageServiceProvider);
      await storage.setActiveWalletId(walletId);

      // Update cached active wallet ID
      _activeWalletId = walletId;

      // Update state (this will trigger SDK reconnection)
      state = AsyncValue.data(wallet);

      log.i('Switched to wallet: $walletId (${wallet.name})');
    } catch (e, stack) {
      log.e('Failed to switch wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Set initial active wallet (typically on first app launch)
  Future<void> setActiveWallet(String walletId) async {
    await switchWallet(walletId);
  }

  /// Clear active wallet (disconnect)
  Future<void> clearActiveWallet() async {
    try {
      log.i('Clearing active wallet');

      final storage = ref.read(walletStorageServiceProvider);
      await storage.clearActiveWallet();

      _activeWalletId = null;
      state = const AsyncValue.data(null);

      log.i('Active wallet cleared');
    } catch (e, stack) {
      log.e('Failed to clear active wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Refresh active wallet from storage
  Future<void> refresh() async {
    log.d('Refreshing active wallet');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(walletStorageServiceProvider);
      final activeId = await storage.getActiveWalletId();

      if (activeId == null) return null;

      final wallets = await ref.read(walletListProvider.future);
      return wallets.where((w) => w.id == activeId).firstOrNull;
    });
  }
}

final activeWalletProvider = AsyncNotifierProvider<ActiveWalletNotifier, WalletMetadata?>(
  ActiveWalletNotifier.new,
);

// ============================================================================
// Derived Providers
// ============================================================================

/// Get mnemonic for active wallet
///
/// Returns null if no active wallet or mnemonic not found
/// SECURITY: Only use this when absolutely necessary (e.g., backup screen)
final activeWalletMnemonicProvider = FutureProvider<String?>((ref) async {
  final log = AppLogger.getLogger('ActiveWalletMnemonic');

  final activeWallet = await ref.watch(activeWalletProvider.future);
  if (activeWallet == null) {
    log.d('No active wallet');
    return null;
  }

  final storage = ref.read(walletStorageServiceProvider);
  final mnemonic = await storage.loadMnemonic(activeWallet.id);

  if (mnemonic != null) {
    log.d('Loaded mnemonic for active wallet (content not logged)');
  } else {
    log.w('Mnemonic not found for active wallet: ${activeWallet.id}');
  }

  return mnemonic;
});

/// Check if any wallets exist
final hasWalletsProvider = Provider<AsyncValue<bool>>((ref) {
  final wallets = ref.watch(walletListProvider);
  return wallets.when(
    data: (list) => AsyncValue.data(list.isNotEmpty),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Get wallet count
final walletCountProvider = Provider<int>((ref) {
  final wallets = ref.watch(walletListProvider);
  return wallets.when(data: (list) => list.length, loading: () => 0, error: (_, _) => 0);
});
