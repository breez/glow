import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/core/logging/logger_mixin.dart';
import 'package:glow/core/services/mnemonic_service.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/features/wallet/widgets/warning_card.dart';

class WalletImportScreen extends ConsumerStatefulWidget {
  const WalletImportScreen({super.key});

  @override
  ConsumerState<WalletImportScreen> createState() => _WalletImportScreenState();
}

class _WalletImportScreenState extends ConsumerState<WalletImportScreen> with LoggerMixin {
  final TextEditingController _nameController = TextEditingController(text: 'Imported Wallet');
  final TextEditingController _mnemonicController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Network _selectedNetwork = Network.mainnet;
  bool _isImporting = false;
  String? _mnemonicError;

  @override
  void dispose() {
    _nameController.dispose();
    _mnemonicController.dispose();
    super.dispose();
  }

  void _validateMnemonic() {
    final String mnemonic = _mnemonicController.text.trim();
    if (mnemonic.isEmpty) {
      setState(() => _mnemonicError = null);
      return;
    }

    final (bool isValid, String? error) = ref.read(mnemonicServiceProvider).validateMnemonic(mnemonic);
    setState(() => _mnemonicError = isValid ? null : error);
  }

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final MnemonicService mnemonicService = ref.read(mnemonicServiceProvider);
    final String normalized = mnemonicService.normalizeMnemonic(_mnemonicController.text);
    final (bool isValid, String? error) = mnemonicService.validateMnemonic(normalized);

    if (!isValid) {
      setState(() => _mnemonicError = error);
      return;
    }

    setState(() => _isImporting = true);

    try {
      final WalletMetadata wallet = await ref
          .read(walletListProvider.notifier)
          .importWallet(name: _nameController.text.trim(), mnemonic: normalized, network: _selectedNetwork);

      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
        Future<void>.delayed(const Duration(milliseconds: 300), () {
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
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            TextFormField(
              controller: _mnemonicController,
              decoration: InputDecoration(
                labelText: '12-Word Recovery Phrase',
                labelStyle: TextStyle(color: themeData.colorScheme.surface),
                hintText: 'word1 word2 word3 ...',
                hintStyle: TextStyle(color: themeData.colorScheme.surface.withValues(alpha: .6)),
                border: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.surface)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeData.colorScheme.surface),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeData.colorScheme.surface),
                ),
                prefixIcon: const Icon(Icons.key, color: Colors.white),
                errorText: _mnemonicError,
                errorMaxLines: 2,
              ),
              maxLines: 3,
              autocorrect: false,
              onChanged: (_) => _validateMnemonic(),
              validator: (String? v) => v == null || v.trim().isEmpty ? 'Enter recovery phrase' : null,
            ),
            const SizedBox(height: 32),
            const WarningCard(
              message:
                  'Never share your recovery phrase. '
                  'Anyone with this phrase can access your funds.',
            ),
            const SizedBox(height: 32),
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
