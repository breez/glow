import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/providers/wallet_provider.dart';
import 'package:glow_breez/screens/wallet_backup_screen.dart';

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
    setState(() => _isCreating = true);

    try {
      final (wallet, mnemonic) = await ref
          .read(walletListProvider.notifier)
          .createWallet(name: _nameController.text.trim(), network: _selectedNetwork);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => WalletBackupScreen(wallet: wallet, mnemonic: mnemonic, isNewWallet: true),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      log.e('Failed to create wallet', error: e);
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Wallet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Wallet Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wallet),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a name';
                if (v.trim().length < 2) return 'At least 2 characters';
                return null;
              },
            ),
            SizedBox(height: 24),
            Text('Network', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            RadioGroup<Network>(
              groupValue: _selectedNetwork,
              onChanged: (v) => setState(() => _selectedNetwork = v!),
              child: Card(
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => setState(() => _selectedNetwork = Network.mainnet),
                      child: Row(
                        children: [
                          Radio<Network>(value: Network.mainnet),
                          Expanded(child: const Text('Mainnet')),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    GestureDetector(
                      onTap: () => setState(() => _selectedNetwork = Network.regtest),
                      child: Row(
                        children: [
                          Radio<Network>(value: Network.regtest),
                          Expanded(child: const Text('Regtest')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            Card(
              color: Colors.orange.withValues(alpha: .1),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will see a 12-word recovery phrase. Write it down securely. '
                        'Anyone with this phrase can access your funds.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            FilledButton(
              onPressed: _isCreating ? null : _createWallet,
              child: _isCreating
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Create Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
