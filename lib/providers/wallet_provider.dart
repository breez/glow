import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/models/wallet_metadata.dart';
import 'package:glow/services/mnemonic_service.dart';
import 'package:glow/services/wallet_storage_service.dart';

class WalletListNotifier extends AsyncNotifier<List<WalletMetadata>> with LoggerMixin {
  late final WalletStorageService _storage;
  late final MnemonicService _mnemonicService;

  @override
  Future<List<WalletMetadata>> build() async {
    _storage = ref.read(walletStorageServiceProvider);
    _mnemonicService = ref.read(mnemonicServiceProvider);

    log.i('Loading wallet list from storage');
    final wallets = await _storage.loadWallets();
    log.i('Loaded ${wallets.length} wallets');
    return wallets;
  }

  Future<(WalletMetadata, String)> createWallet({required String name, required Network network}) async {
    if (name.trim().isEmpty) throw Exception('Wallet name cannot be empty');

    try {
      log.i('Creating new wallet: $name on ${network.name}');

      final mnemonic = _mnemonicService.generateMnemonic();
      final walletId = WalletStorageService.generateWalletId(mnemonic);
      final wallet = WalletMetadata(id: walletId, name: name);

      await _storage.addWallet(wallet, mnemonic);
      state = AsyncValue.data([...state.value ?? [], wallet]);

      log.i('Created wallet: $walletId ($name)');
      return (wallet, mnemonic);
    } catch (e, stack) {
      log.e('Failed to create wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<WalletMetadata> importWallet({
    required String name,
    required String mnemonic,
    required Network network,
  }) async {
    try {
      log.i('Importing wallet: $name on ${network.name}');

      final normalized = _mnemonicService.normalizeMnemonic(mnemonic);
      final (isValid, error) = _mnemonicService.validateMnemonic(normalized);

      if (!isValid) {
        log.w('Invalid mnemonic: $error');
        throw Exception('Invalid mnemonic: $error');
      }

      final walletId = WalletStorageService.generateWalletId(normalized);
      final existingWallets = state.value ?? [];

      if (existingWallets.any((w) => w.id == walletId)) {
        log.w('Wallet already exists: $walletId');
        throw Exception('This wallet already exists');
      }

      final wallet = WalletMetadata(id: walletId, name: name);
      await _storage.addWallet(wallet, normalized);

      state = AsyncValue.data([...existingWallets, wallet]);

      log.i('Imported wallet: $walletId ($name)');
      return wallet;
    } catch (e, stack) {
      log.e('Failed to import wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> updateWalletName(String walletId, String newName) async {
    try {
      log.i('Updating wallet name: $walletId -> $newName');

      final wallets = state.value ?? [];
      final index = wallets.indexWhere((w) => w.id == walletId);
      if (index == -1) throw Exception('Wallet not found: $walletId');

      final updated = wallets[index].copyWith(name: newName);
      await _storage.updateWallet(updated);

      state = AsyncValue.data([...wallets]..[index] = updated);
      log.i('Wallet name updated: $walletId');
    } catch (e, stack) {
      log.e('Failed to update wallet name', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      log.w('Deleting wallet: $walletId');
      await _storage.deleteWallet(walletId);

      state = AsyncValue.data((state.value ?? []).where((w) => w.id != walletId).toList());
      log.i('Wallet deleted: $walletId');
    } catch (e, stack) {
      log.e('Failed to delete wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

final walletListProvider = AsyncNotifierProvider<WalletListNotifier, List<WalletMetadata>>(
  WalletListNotifier.new,
);

// ============================================================================
// Active Wallet Management
// ============================================================================

class ActiveWalletNotifier extends AsyncNotifier<WalletMetadata?> with LoggerMixin {
  late final WalletStorageService _storage;
  String? _activeWalletId;

  @override
  Future<WalletMetadata?> build() async {
    _storage = ref.read(walletStorageServiceProvider);
    log.i('Loading active wallet');

    _activeWalletId ??= await _storage.getActiveWalletId();

    if (_activeWalletId == null) {
      log.i('No active wallet set');
      return null;
    }

    final wallets = await ref.watch(walletListProvider.future);
    final wallet = wallets.where((w) => w.id == _activeWalletId).firstOrNull;

    if (wallet != null) {
      log.i('Active wallet: ${wallet.id} (${wallet.name})');
      return wallet;
    }

    log.w('Active wallet not found in list: $_activeWalletId');
    await _storage.clearActiveWallet();
    _activeWalletId = null;
    return null;
  }

  Future<void> switchWallet(String walletId) async {
    try {
      log.i('Switching to wallet: $walletId');

      final wallets = await ref.read(walletListProvider.future);
      final wallet = wallets.where((w) => w.id == walletId).firstOrNull;
      if (wallet == null) throw Exception('Wallet not found: $walletId');

      await _storage.setActiveWalletId(walletId);
      _activeWalletId = walletId;
      state = AsyncValue.data(wallet);

      log.i('Switched to wallet: $walletId (${wallet.name})');
    } catch (e, stack) {
      log.e('Failed to switch wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> setActiveWallet(String walletId) => switchWallet(walletId);

  Future<void> clearActiveWallet() async {
    try {
      log.i('Clearing active wallet');
      await _storage.clearActiveWallet();
      _activeWalletId = null;
      state = const AsyncValue.data(null);
      log.i('Active wallet cleared');
    } catch (e, stack) {
      log.e('Failed to clear active wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

final activeWalletProvider = AsyncNotifierProvider<ActiveWalletNotifier, WalletMetadata?>(
  ActiveWalletNotifier.new,
);

// ============================================================================
// Derived Providers
// ============================================================================

final hasWalletsProvider = Provider<AsyncValue<bool>>((ref) {
  final wallets = ref.watch(walletListProvider);
  return wallets.when(
    data: (list) => AsyncValue.data(list.isNotEmpty),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final walletCountProvider = Provider<int>((ref) {
  final wallets = ref.watch(walletListProvider);
  return wallets.when(data: (list) => list.length, loading: () => 0, error: (_, _) => 0);
});
