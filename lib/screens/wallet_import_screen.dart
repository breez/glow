import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/providers/mnemonic_service_provider.dart';
import 'package:glow_breez/providers/wallet_provider.dart';

/// Screen for importing an existing wallet from mnemonic
///
/// Flow:
/// 1. User enters wallet name
/// 2. Pastes/types 12-word mnemonic
/// 3. Selects network
/// 4. Validates mnemonic
/// 5. Imports wallet (marked as backed up)
/// 6. Returns to wallet list
class WalletImportScreen extends ConsumerStatefulWidget {
  const WalletImportScreen({super.key});

  @override
  ConsumerState<WalletImportScreen> createState() => _WalletImportScreenState();
}

class _WalletImportScreenState extends ConsumerState<WalletImportScreen> with LoggerMixin {
  final _nameController = TextEditingController(text: 'Imported Wallet');
  final _mnemonicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Network _selectedNetwork = Network.mainnet;
  bool _isImporting = false;
  String? _mnemonicError;

  @override
  void dispose() {
    _nameController.dispose();
    _mnemonicController.dispose();
    super.dispose();
  }

  /// Validate mnemonic in real-time
  void _validateMnemonic() {
    final mnemonic = _mnemonicController.text.trim();
    if (mnemonic.isEmpty) {
      setState(() {
        _mnemonicError = null;
      });
      return;
    }

    final mnemonicService = ref.read(mnemonicServiceProvider);
    final (isValid, error) = mnemonicService.validateMnemonic(mnemonic);

    setState(() {
      _mnemonicError = isValid ? null : error;
    });
  }

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) return;

    // Final validation
    final mnemonicService = ref.read(mnemonicServiceProvider);
    final normalized = mnemonicService.normalizeMnemonic(_mnemonicController.text);
    final (isValid, error) = mnemonicService.validateMnemonic(normalized);

    if (!isValid) {
      setState(() {
        _mnemonicError = error;
      });
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      log.i('Importing wallet: ${_nameController.text} on ${_selectedNetwork.name}');

      final wallet = await ref
          .read(walletListProvider.notifier)
          .importWallet(name: _nameController.text.trim(), mnemonic: normalized, network: _selectedNetwork);

      log.i('Wallet imported successfully: ${wallet.id}');

      // Set as active wallet
      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      if (!mounted) return;

      // Navigate to main screen and clear navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      // Show success message after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wallet "${wallet.name}" imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e, stack) {
      log.e('Failed to import wallet', error: e, stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Text('Import Existing Wallet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Enter your 12-word recovery phrase to restore your wallet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Wallet Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Wallet Name',
                hintText: 'Imported Wallet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wallet),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a wallet name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Mnemonic Input
            TextFormField(
              controller: _mnemonicController,
              decoration: InputDecoration(
                labelText: '12-Word Recovery Phrase',
                hintText: 'word1 word2 word3 ... word12',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                errorText: _mnemonicError,
                errorMaxLines: 2,
                helperText: 'Enter words separated by spaces',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              onChanged: (_) => _validateMnemonic(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your recovery phrase';
                }
                // Additional validation done on import
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Network Selection
            Text('Network', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  RadioListTile<Network>(
                    title: const Text('Mainnet'),
                    subtitle: const Text('Real Bitcoin transactions'),
                    value: Network.mainnet,
                    groupValue: _selectedNetwork,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedNetwork = value;
                        });
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<Network>(
                    title: const Text('Regtest'),
                    subtitle: const Text('Testing only - no real funds'),
                    value: Network.regtest,
                    groupValue: _selectedNetwork,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedNetwork = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Security Warning
            Card(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Notice',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Never share your recovery phrase with anyone. Anyone with access to it can steal your funds.',
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Import Button
            FilledButton(
              onPressed: (_isImporting || _mnemonicError != null) ? null : _importWallet,
              child: _isImporting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Import Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
