import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/models/wallet_metadata.dart';
import 'package:glow_breez/providers/wallet_provider.dart';

class WalletBackupScreen extends ConsumerStatefulWidget {
  final WalletMetadata wallet;
  final String mnemonic;
  final bool isNewWallet;

  const WalletBackupScreen({
    super.key,
    required this.wallet,
    required this.mnemonic,
    required this.isNewWallet,
  });

  @override
  ConsumerState<WalletBackupScreen> createState() => _WalletBackupScreenState();
}

class _WalletBackupScreenState extends ConsumerState<WalletBackupScreen> with LoggerMixin {
  bool _isConfirming = false;

  List<String> get _words => widget.mnemonic.split(' ');

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);

    try {
      await ref.read(activeWalletProvider.notifier).setActiveWallet(widget.wallet.id);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Wallet backed up!'), backgroundColor: Colors.green));
          }
        });
      }
    } catch (e) {
      log.e('Failed to confirm backup', error: e);
      setState(() => _isConfirming = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backup Wallet'), automaticallyImplyLeading: !widget.isNewWallet),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Card(
            color: Colors.orange.withValues(alpha: .1),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Write This Down!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'This recovery phrase is the ONLY way to recover your funds if you lose your phone.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Recovery Phrase', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.mnemonic));
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Copied to clipboard')));
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (_, i) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text('${i + 1}.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(width: 8),
                          Text(_words[i], style: TextStyle(fontSize: 14, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Security Tips', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 12),
                  _tip(Icons.edit_note, 'Write on paper (no screenshots)'),
                  _tip(Icons.security, 'Store in a secure location'),
                  _tip(Icons.do_not_disturb, 'Never share with anyone'),
                  _tip(Icons.verified_user, 'Keep multiple copies'),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          FilledButton(
            onPressed: _isConfirming ? null : _confirm,
            child: _isConfirming
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('I Have Written It Down'),
          ),
          if (!widget.isNewWallet) ...[
            SizedBox(height: 16),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ],
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
