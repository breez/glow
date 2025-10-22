import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/providers/wallet_provider.dart';
import 'package:glow_breez/screens/wallet_backup_screen.dart';

/// Screen for creating a new wallet
///
/// Flow:
/// 1. User enters wallet name
/// 2. Selects network (mainnet/regtest)
/// 3. Creates wallet with generated mnemonic
/// 4. Navigates to backup screen
class WalletCreateScreen extends ConsumerStatefulWidget {
  const WalletCreateScreen({super.key});

  @override
  ConsumerState<WalletCreateScreen> createState() => _WalletCreateScreenState();
}

class _WalletCreateScreenState extends ConsumerState<WalletCreateScreen> with LoggerMixin {
  final _nameController = TextEditingController(text: 'My Wallet');
  final _formKey = GlobalKey<FormState>();
  Network _selectedNetwork = Network.mainnet;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      log.i('Creating wallet: ${_nameController.text} on ${_selectedNetwork.name}');

      // Create wallet with generated mnemonic
      final (wallet, mnemonic) = await ref
          .read(walletListProvider.notifier)
          .createWallet(name: _nameController.text.trim(), network: _selectedNetwork);

      log.i('Wallet created: ${wallet.id}');

      if (!mounted) return;

      // Navigate to backup screen (CRITICAL: User must backup mnemonic)
      // Use pushAndRemoveUntil to clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => WalletBackupScreen(wallet: wallet, mnemonic: mnemonic, isNewWallet: true),
        ),
        (route) => false, // Remove all previous routes
      );
    } catch (e, stack) {
      log.e('Failed to create wallet', error: e, stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create wallet: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Wallet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Text('Create a New Wallet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'A new 12-word recovery phrase will be generated for you',
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
                hintText: 'My Wallet',
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

            // Warning Card
            Card(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You will be shown a 12-word recovery phrase. Write it down and keep it safe. Anyone with this phrase can access your funds.',
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

            // Create Button
            FilledButton(
              onPressed: _isCreating ? null : _createWallet,
              child: _isCreating
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
