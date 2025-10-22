import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/models/wallet_metadata.dart';
import 'package:glow_breez/providers/wallet_provider.dart';

/// Screen for backing up wallet mnemonic with verification
///
/// Two-step process:
/// 1. Show mnemonic with "Write Down" instructions
/// 2. Verify user wrote it down by asking them to re-enter random words
///
/// Only after verification is the wallet marked as backed up
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
  bool _showingVerification = false;
  final _verificationControllers = <TextEditingController>[];
  List<int> _verificationIndices = [];
  bool _isVerifying = false;

  @override
  void dispose() {
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _mnemonicWords => widget.mnemonic.split(' ');

  void _startVerification() {
    // Pick 3 random word indices for verification
    final words = _mnemonicWords;
    final indices = <int>[];

    while (indices.length < 3) {
      final index = DateTime.now().millisecondsSinceEpoch % words.length;
      if (!indices.contains(index)) {
        indices.add(index);
      }
    }

    indices.sort();

    setState(() {
      _verificationIndices = indices;
      _verificationControllers.clear();
      for (var i = 0; i < 3; i++) {
        _verificationControllers.add(TextEditingController());
      }
      _showingVerification = true;
    });

    log.i('Starting mnemonic verification for wallet: ${widget.wallet.id}');
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
    });

    final words = _mnemonicWords;
    bool allCorrect = true;

    for (var i = 0; i < _verificationIndices.length; i++) {
      final wordIndex = _verificationIndices[i];
      final expectedWord = words[wordIndex];
      final enteredWord = _verificationControllers[i].text.trim().toLowerCase();

      if (expectedWord != enteredWord) {
        allCorrect = false;
        break;
      }
    }

    if (!allCorrect) {
      setState(() {
        _isVerifying = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect words. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      log.w('Mnemonic verification failed for wallet: ${widget.wallet.id}');
      return;
    }

    // Mark wallet as backed up
    try {
      await ref.read(walletListProvider.notifier).markAsBackedUp(widget.wallet.id);

      // Set as active wallet
      await ref.read(activeWalletProvider.notifier).setActiveWallet(widget.wallet.id);

      log.i('Wallet backed up and activated: ${widget.wallet.id}');

      if (!mounted) return;

      // Navigate to main screen (clear entire navigation stack)
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      // Show success message after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wallet backup verified!'), backgroundColor: Colors.green),
          );
        }
      });
    } catch (e, stack) {
      log.e('Failed to mark wallet as backed up', error: e, stackTrace: stack);

      setState(() {
        _isVerifying = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save backup status: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingVerification) {
      return _buildVerificationScreen();
    }

    return _buildBackupScreen();
  }

  Widget _buildBackupScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Wallet'),
        // Don't allow back navigation for new wallets
        automaticallyImplyLeading: !widget.isNewWallet,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Warning Header
          Card(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Write This Down!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This is your recovery phrase. Write it down on paper and store it safely. If you lose your phone, this is the ONLY way to recover your funds.',
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mnemonic Display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Recovery Phrase', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.mnemonic));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid of words with numbers
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _mnemonicWords[index],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security Tips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Security Tips', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildTip(Icons.edit_note, 'Write it down on paper (don\'t take a screenshot)'),
                  _buildTip(Icons.security, 'Store it in a secure location'),
                  _buildTip(Icons.do_not_disturb, 'Never share it with anyone'),
                  _buildTip(Icons.verified_user, 'Keep multiple copies in different locations'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Continue Button
          FilledButton(onPressed: _startVerification, child: const Text('I Have Written It Down')),
          const SizedBox(height: 16),

          if (!widget.isNewWallet)
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _buildVerificationScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Backup'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Instructions
          Text('Verify Your Backup', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Enter the following words from your recovery phrase to confirm you wrote it down correctly.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Verification fields
          for (var i = 0; i < _verificationIndices.length; i++) ...[
            TextFormField(
              controller: _verificationControllers[i],
              decoration: InputDecoration(
                labelText: 'Word #${_verificationIndices[i] + 1}',
                border: const OutlineInputBorder(),
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),

          // Verify Button
          FilledButton(
            onPressed: _isVerifying ? null : _verify,
            child: _isVerifying
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Verify'),
          ),
          const SizedBox(height: 12),

          // Back button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _showingVerification = false;
              });
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
