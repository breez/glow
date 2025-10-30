import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/services/mnemonic_service.dart';
import 'package:glow/providers/wallet_provider.dart';

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

  void _validateMnemonic() {
    final mnemonic = _mnemonicController.text.trim();
    if (mnemonic.isEmpty) {
      setState(() => _mnemonicError = null);
      return;
    }

    final (isValid, error) = ref.read(mnemonicServiceProvider).validateMnemonic(mnemonic);
    setState(() => _mnemonicError = isValid ? null : error);
  }

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) return;

    final mnemonicService = ref.read(mnemonicServiceProvider);
    final normalized = mnemonicService.normalizeMnemonic(_mnemonicController.text);
    final (isValid, error) = mnemonicService.validateMnemonic(normalized);

    if (!isValid) {
      setState(() => _mnemonicError = error);
      return;
    }

    setState(() => _isImporting = true);

    try {
      final wallet = await ref
          .read(walletListProvider.notifier)
          .importWallet(name: _nameController.text.trim(), mnemonic: normalized, network: _selectedNetwork);

      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Wallet "${wallet.name}" imported!'), backgroundColor: Colors.green),
            );
          }
        });
      }
    } catch (e) {
      log.e('Failed to import wallet', error: e);
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import Wallet')),
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
            TextFormField(
              controller: _mnemonicController,
              decoration: InputDecoration(
                labelText: '12-Word Recovery Phrase',
                hintText: 'word1 word2 word3 ...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                errorText: _mnemonicError,
                errorMaxLines: 2,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              onChanged: (_) => _validateMnemonic(),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter recovery phrase' : null,
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
                    Icon(Icons.security, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Never share your recovery phrase. '
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
              onPressed: (_isImporting || _mnemonicError != null) ? null : _importWallet,
              child: _isImporting
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Import Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
