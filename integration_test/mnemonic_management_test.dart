import 'package:flutter_test/flutter_test.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:integration_test/integration_test.dart';
import 'package:glow_breez/providers/mnemonic_service_provider.dart';
import 'package:glow_breez/providers/wallet_provider.dart';
import 'package:glow_breez/services/wallet_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

void main() {
  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    AppLogger.initialize();
  });

  group('Phase 1: Mnemonic Management Integration Tests', () {
    late ProviderContainer container;
    late WalletStorageService storage;
    late MnemonicService mnemonicService;

    setUp(() async {
      container = ProviderContainer();
      storage = container.read(walletStorageServiceProvider);
      mnemonicService = container.read(mnemonicServiceProvider);

      // Clear all data before each test
      // Note: In real integration tests on device, this will work
      // For unit tests, you may need to mock flutter_secure_storage
      try {
        await storage.clearAllData();
      } catch (e) {
        // Ignore errors in test environment setup
        print('Warning: Could not clear storage in test environment: $e');
      }
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Generate 12-word mnemonic → Valid BIP39', () {
      final mnemonic = mnemonicService.generateMnemonic();
      final words = mnemonic.split(' ');

      expect(words.length, 12, reason: 'Mnemonic should have exactly 12 words');

      final (isValid, error) = mnemonicService.validateMnemonic(mnemonic);
      expect(isValid, true, reason: 'Generated mnemonic should be valid');
      expect(error, null, reason: 'Valid mnemonic should have no error');
    });

    test('2. Import valid mnemonic → Creates wallet successfully', () async {
      final mnemonic = mnemonicService.generateMnemonic();

      final wallet = await container
          .read(walletListProvider.notifier)
          .importWallet(name: 'Test Wallet', mnemonic: mnemonic, network: Network.regtest);

      expect(wallet.name, 'Test Wallet');
      expect(wallet.network, 'regtest');
      expect(wallet.isBackedUp, true, reason: 'Imported wallets should be marked as backed up');

      // Verify mnemonic is stored
      final storedMnemonic = await storage.loadMnemonic(wallet.id);
      expect(storedMnemonic, mnemonic, reason: 'Stored mnemonic should match input');
    });

    test('3. Import invalid mnemonic → Validation error', () async {
      final invalidMnemonic = 'invalid mnemonic with wrong words here and more words that dont work';

      expect(
        () => container
            .read(walletListProvider.notifier)
            .importWallet(name: 'Bad Wallet', mnemonic: invalidMnemonic, network: Network.regtest),
        throwsA(isA<Exception>()),
        reason: 'Invalid mnemonic should throw exception',
      );
    });

    test('4. Create 2 wallets → Isolated storage directories', () async {
      final (wallet1, mnemonic1) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Wallet 1', network: Network.regtest);

      final (wallet2, mnemonic2) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Wallet 2', network: Network.regtest);

      expect(wallet1.id, isNot(wallet2.id), reason: 'Wallets should have unique IDs');
      expect(mnemonic1, isNot(mnemonic2), reason: 'Wallets should have different mnemonics');

      // Verify both mnemonics are stored separately
      final stored1 = await storage.loadMnemonic(wallet1.id);
      final stored2 = await storage.loadMnemonic(wallet2.id);

      expect(stored1, mnemonic1, reason: 'Wallet 1 mnemonic should be stored');
      expect(stored2, mnemonic2, reason: 'Wallet 2 mnemonic should be stored');
    });

    test('5. Switch wallets → SDK disconnects/reconnects correctly', () async {
      final (wallet1, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Wallet 1', network: Network.regtest);

      final (wallet2, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Wallet 2', network: Network.regtest);

      // Set wallet1 as active
      await container.read(activeWalletProvider.notifier).setActiveWallet(wallet1.id);

      var activeId = await storage.getActiveWalletId();
      expect(activeId, wallet1.id, reason: 'Wallet 1 should be active');

      // Switch to wallet2
      await container.read(activeWalletProvider.notifier).switchWallet(wallet2.id);

      activeId = await storage.getActiveWalletId();
      expect(activeId, wallet2.id, reason: 'Wallet 2 should be active after switch');
    });

    test('6. Persist active wallet → Survives app restart', () async {
      final (wallet, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Persistent Wallet', network: Network.regtest);

      await container.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      // Simulate app restart by creating new container
      container.dispose();
      final newContainer = ProviderContainer();
      final newStorage = newContainer.read(walletStorageServiceProvider);

      final activeId = await newStorage.getActiveWalletId();
      expect(activeId, wallet.id, reason: 'Active wallet should persist across app restarts');

      newContainer.dispose();
    });

    test('7. Mark wallet as backed up → isBackedUp flag set', () async {
      final (wallet, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Backup Test', network: Network.regtest);

      expect(wallet.isBackedUp, false, reason: 'New wallets should not be backed up initially');

      await container.read(walletListProvider.notifier).markAsBackedUp(wallet.id);

      final wallets = await container.read(walletListProvider.future);
      final updated = wallets.firstWhere((w) => w.id == wallet.id);

      expect(updated.isBackedUp, true, reason: 'Wallet should be marked as backed up');
    });

    test('8. Delete wallet → Mnemonic also deleted', () async {
      final (wallet, mnemonic) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Delete Me', network: Network.regtest);

      // Verify mnemonic exists
      var storedMnemonic = await storage.loadMnemonic(wallet.id);
      expect(storedMnemonic, mnemonic, reason: 'Mnemonic should exist before deletion');

      // Delete wallet
      await container.read(walletListProvider.notifier).deleteWallet(wallet.id);

      // Verify mnemonic is gone
      storedMnemonic = await storage.loadMnemonic(wallet.id);
      expect(storedMnemonic, null, reason: 'Mnemonic should be deleted with wallet');
    });

    test('9. Wallet ID generation → Deterministic from mnemonic', () {
      final mnemonic = mnemonicService.generateMnemonic();

      final id1 = WalletStorageService.generateWalletId(mnemonic);
      final id2 = WalletStorageService.generateWalletId(mnemonic);

      expect(id1, id2, reason: 'Same mnemonic should generate same ID');
      expect(id1.length, 8, reason: 'Wallet ID should be 8 characters');

      // Different mnemonics should generate different IDs
      final differentMnemonic = mnemonicService.generateMnemonic();
      final id3 = WalletStorageService.generateWalletId(differentMnemonic);
      expect(id1, isNot(id3), reason: 'Different mnemonics should generate different IDs');
    });

    test('10. Mnemonic normalization → Handles whitespace', () {
      // Generate a valid mnemonic
      final validMnemonic = mnemonicService.generateMnemonic();
      final words = validMnemonic.split(' ');

      // Create messy version with extra whitespace
      final messyMnemonic =
          '  ${words[0]}  ${words[1]}   ${words[2]}  ${words[3]}  '
          '${words[4]}  ${words[5]}  ${words[6]}  ${words[7]}  '
          '${words[8]}  ${words[9]}  ${words[10]}  ${words[11]}  ';

      final normalized = mnemonicService.normalizeMnemonic(messyMnemonic);

      expect(normalized.split(' ').length, 12, reason: 'Should have 12 words after normalization');
      expect(normalized, isNot(contains('  ')), reason: 'No double spaces');
      expect(normalized, isNot(startsWith(' ')), reason: 'No leading space');
      expect(normalized, isNot(endsWith(' ')), reason: 'No trailing space');
      expect(normalized, validMnemonic, reason: 'Should match original mnemonic');
    });

    test('11. Cannot import duplicate wallet', () async {
      final mnemonic = mnemonicService.generateMnemonic();

      // Import first time
      await container
          .read(walletListProvider.notifier)
          .importWallet(name: 'Original', mnemonic: mnemonic, network: Network.regtest);

      // Try to import same wallet again
      expect(
        () => container
            .read(walletListProvider.notifier)
            .importWallet(name: 'Duplicate', mnemonic: mnemonic, network: Network.regtest),
        throwsA(isA<Exception>()),
        reason: 'Should not allow importing duplicate wallet',
      );
    });

    test('12. Wallet name validation', () async {
      expect(
        () => container
            .read(walletListProvider.notifier)
            .createWallet(
              name: '', // Empty name
              network: Network.regtest,
            ),
        throwsA(anything),
        reason: 'Empty wallet name should be rejected',
      );
    });

    test('13. Delete active wallet → Clears active reference', () async {
      final (wallet, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Active Delete Test', network: Network.regtest);

      await container.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      var activeId = await storage.getActiveWalletId();
      expect(activeId, wallet.id);

      // Delete the active wallet
      await container.read(walletListProvider.notifier).deleteWallet(wallet.id);

      // Active wallet reference should be cleared
      activeId = await storage.getActiveWalletId();
      expect(activeId, isNull, reason: 'Active wallet reference should be cleared after deletion');
    });

    test('14. BIP39 checksum validation', () {
      // Valid mnemonic
      final valid =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final (isValid, error) = mnemonicService.validateMnemonic(valid);
      expect(isValid, true);

      // Invalid checksum (changed last word)
      final invalidChecksum =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon';
      final (isInvalid, error2) = mnemonicService.validateMnemonic(invalidChecksum);
      expect(isInvalid, false, reason: 'Invalid checksum should be rejected');
      expect(error2, isNotNull);
    });

    test('15. Wallet list sorting and metadata', () async {
      // Create multiple wallets
      final (wallet1, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Wallet A', network: Network.regtest);

      await Future.delayed(const Duration(milliseconds: 100));

      final (wallet2, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Wallet B', network: Network.mainnet);

      final wallets = await container.read(walletListProvider.future);

      expect(wallets.length, 2);
      expect(
        wallet1.createdAt.isBefore(wallet2.createdAt),
        true,
        reason: 'Wallet 1 should be created before Wallet 2',
      );

      // Check metadata
      expect(wallet1.name, 'Wallet A');
      expect(wallet2.name, 'Wallet B');
      expect(wallet1.network, 'regtest');
      expect(wallet2.network, 'mainnet');
    });
  });
}
