import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:glow/core/providers/wallet_provider.dart';

final log = AppLogger.getLogger('SetupActions');
final AutoSizeGroup _autoSizeGroup = AutoSizeGroup();

class SetupActions extends StatelessWidget {
  const SetupActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _RegisterButton(autoSizeGroup: _autoSizeGroup),
        const SizedBox(height: 24),
        _RestoreButton(autoSizeGroup: _autoSizeGroup),
      ],
    );
  }
}

class _RegisterButton extends ConsumerStatefulWidget {
  final AutoSizeGroup autoSizeGroup;

  const _RegisterButton({required this.autoSizeGroup});

  @override
  ConsumerState<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends ConsumerState<_RegisterButton> {
  bool _isCreating = false;

  String _generateWalletName() {
    final random = Random();
    final digits = random.nextInt(10000).toString().padLeft(4, '0');
    return 'Glow$digits';
  }

  Future<void> _handleCreateWallet() async {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      final walletName = _generateWalletName();
      log.i('Creating wallet: $walletName on mainnet');

      final (wallet, mnemonic) = await ref
          .read(walletListProvider.notifier)
          .createWallet(name: walletName, network: Network.mainnet);

      // Set as active wallet
      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      if (mounted) {
        // Navigate to home screen, removing all previous routes
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);

        // Show success message after navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Wallet "${wallet.name}" created successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e, stack) {
      log.e('Failed to create wallet', error: e, stackTrace: stack);
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create wallet: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: 48.0,
      width: min(screenSize.width * 0.5, 168),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeData.colorScheme.secondary,
          elevation: 0.0,
          disabledBackgroundColor: themeData.disabledColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        onPressed: _isCreating ? null : _handleCreateWallet,
        child: _isCreating
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: themeData.primaryColor),
              )
            : Semantics(
                button: true,
                label: 'LET\'S GLOW!',
                child: AutoSizeText(
                  'LET\'S GLOW!',
                  style: themeData.textTheme.labelLarge?.copyWith(color: themeData.primaryColor),
                  stepGranularity: 0.1,
                  group: widget.autoSizeGroup,
                  maxLines: 1,
                ),
              ),
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  final AutoSizeGroup autoSizeGroup;

  const _RestoreButton({required this.autoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: 48.0,
      width: min(screenSize.width * 0.5, 168),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white),
          elevation: 0.0,
          disabledBackgroundColor: themeData.disabledColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.walletImport),
        child: Semantics(
          button: true,
          label: 'Restore using mnemonics',
          child: AutoSizeText(
            'RESTORE',
            style: themeData.textTheme.labelLarge?.copyWith(color: Colors.white),
            stepGranularity: 0.1,
            group: autoSizeGroup,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
