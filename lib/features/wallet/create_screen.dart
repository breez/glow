import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/core/logging/logger_mixin.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/features/wallet/widgets/network_selector.dart';
import 'package:glow/features/wallet/widgets/wallet_name_field.dart';
import 'package:glow/features/wallet/widgets/warning_card.dart';

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

      // Set as active wallet
      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      if (mounted) {
        // Go directly to home screen
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);

        // Show success message after navigation
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Wallet "${wallet.name}" created!'), backgroundColor: Colors.green),
            );
          }
        });
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
            WalletNameField(controller: _nameController),
            SizedBox(height: 24),
            NetworkSelector(
              selectedNetwork: _selectedNetwork,
              onChanged: (v) => setState(() => _selectedNetwork = v),
            ),
            SizedBox(height: 32),
            WarningCard(
              message:
                  'You will see a 12-word recovery phrase after creating your wallet. Write it down securely. '
                  'Anyone with this phrase can access your funds.',
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
