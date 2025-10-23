import 'package:flutter_test/flutter_test.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:integration_test/integration_test.dart';
import 'package:glow_breez/services/mnemonic_service.dart';
import 'package:glow_breez/providers/wallet_provider.dart';
import 'package:glow_breez/services/wallet_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

void main() {
  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    AppLogger.initialize();
  });

  group('Mnemonic Management', () {
    late ProviderContainer container;
    late WalletStorageService storage;
    late MnemonicService mnemonicService;

    setUp(() {
      container = ProviderContainer();
      storage = container.read(walletStorageServiceProvider);
      mnemonicService = container.read(mnemonicServiceProvider);
    });

    tearDown(() => container.dispose());

    test('Generate valid 12-word mnemonic', () {
      final mnemonic = mnemonicService.generateMnemonic();
      expect(mnemonic.split(' ').length, 12);

      final (isValid, error) = mnemonicService.validateMnemonic(mnemonic);
      expect(isValid, true);
      expect(error, null);
    });

    test('Import valid mnemonic', () async {
      final mnemonic = mnemonicService.generateMnemonic();
      final wallet = await container
          .read(walletListProvider.notifier)
          .importWallet(name: 'Test', mnemonic: mnemonic, network: Network.regtest);

      expect(await storage.loadMnemonic(wallet.id), mnemonic);
    });

    test('Reject invalid mnemonic', () {
      expect(
        () => container
            .read(walletListProvider.notifier)
            .importWallet(name: 'Bad', mnemonic: 'invalid words here', network: Network.regtest),
        throwsA(isA<Exception>()),
      );
    });

    test('Create multiple wallets with isolated storage', () async {
      final (w1, m1) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'W1', network: Network.regtest);
      final (w2, m2) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'W2', network: Network.regtest);

      expect(w1.id, isNot(w2.id));
      expect(await storage.loadMnemonic(w1.id), m1);
      expect(await storage.loadMnemonic(w2.id), m2);
    });

    test('Switch active wallet', () async {
      final (w1, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'W1', network: Network.regtest);
      final (w2, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'W2', network: Network.regtest);

      await container.read(activeWalletProvider.notifier).setActiveWallet(w1.id);
      expect(await storage.getActiveWalletId(), w1.id);

      await container.read(activeWalletProvider.notifier).switchWallet(w2.id);
      expect(await storage.getActiveWalletId(), w2.id);
    });

    test('Persist active wallet across restart', () async {
      final (wallet, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Persistent', network: Network.regtest);
      await container.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      container.dispose();
      final newContainer = ProviderContainer();
      expect(await newContainer.read(walletStorageServiceProvider).getActiveWalletId(), wallet.id);
      newContainer.dispose();
    });

    test('Delete wallet removes mnemonic', () async {
      final (wallet, mnemonic) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Delete', network: Network.regtest);

      expect(await storage.loadMnemonic(wallet.id), mnemonic);
      await container.read(walletListProvider.notifier).deleteWallet(wallet.id);
      expect(await storage.loadMnemonic(wallet.id), null);
    });

    test('Deterministic wallet ID from mnemonic', () {
      final mnemonic = mnemonicService.generateMnemonic();
      final id1 = WalletStorageService.generateWalletId(mnemonic);
      final id2 = WalletStorageService.generateWalletId(mnemonic);
      final id3 = WalletStorageService.generateWalletId(mnemonicService.generateMnemonic());

      expect(id1, id2);
      expect(id1.length, 8);
      expect(id1, isNot(id3));
    });

    test('Normalize whitespace in mnemonic', () {
      final valid = mnemonicService.generateMnemonic();
      final messy = '  ${valid.replaceAll(' ', '   ')}  ';
      final normalized = mnemonicService.normalizeMnemonic(messy);

      expect(normalized, valid);
      expect(normalized, isNot(contains('  ')));
    });

    test('Prevent duplicate wallet import', () async {
      final mnemonic = mnemonicService.generateMnemonic();
      await container
          .read(walletListProvider.notifier)
          .importWallet(name: 'Original', mnemonic: mnemonic, network: Network.regtest);

      expect(
        () => container
            .read(walletListProvider.notifier)
            .importWallet(name: 'Duplicate', mnemonic: mnemonic, network: Network.regtest),
        throwsA(isA<Exception>()),
      );
    });

    test('Reject empty wallet name', () {
      expect(
        () => container.read(walletListProvider.notifier).createWallet(name: '', network: Network.regtest),
        throwsA(anything),
      );
    });

    test('Clear active wallet on deletion', () async {
      final (wallet, _) = await container
          .read(walletListProvider.notifier)
          .createWallet(name: 'Active', network: Network.regtest);
      await container.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);
      await container.read(walletListProvider.notifier).deleteWallet(wallet.id);

      expect(await storage.getActiveWalletId(), null);
    });

    test('Validate BIP39 checksum', () {
      final valid =
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon about';
      expect(mnemonicService.validateMnemonic(valid).$1, true);

      final invalid = valid.replaceAll('about', 'abandon');
      final (isValid, error) = mnemonicService.validateMnemonic(invalid);
      expect(isValid, false);
      expect(error, isNotNull);
    });
  });
}
