import 'dart:io';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:glow_breez/providers/sdk_provider.dart';
import 'package:share_plus/share_plus.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final mnemonic = ref.watch(mnemonicProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Network Switch Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Network', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Switch between mainnet and regtest',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: network == Network.mainnet
                              ? null
                              : () {
                                  ref.read(networkProvider.notifier).setNetwork(Network.mainnet);
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: network == Network.mainnet
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: network == Network.mainnet
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                          child: const Text('Mainnet'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: network == Network.regtest
                              ? null
                              : () {
                                  ref.read(networkProvider.notifier).setNetwork(Network.regtest);
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: network == Network.regtest
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: network == Network.regtest
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                          child: const Text('Regtest'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Mnemonic Management Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mnemonic', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your wallet seed phrase',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  
                  // Display masked mnemonic
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _maskMnemonic(mnemonic),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showChangeMnemonicDialog(context, ref),
                          icon: const Icon(Icons.edit),
                          label: const Text('Change Mnemonic'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMnemonicDialog(context, mnemonic),
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Full'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logs', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Share logs for debugging',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Share current session
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.share),
                    title: const Text('Share Current Session'),
                    subtitle: const Text('Share logs from this session only'),
                    onTap: () => _shareCurrentSession(context),
                  ),
                  const Divider(),

                  // Share all logs
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_zip),
                    title: const Text('Share All Logs'),
                    subtitle: const Text('Share all session logs (last 10)'),
                    onTap: () => _shareAllLogs(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Log info
          FutureBuilder<int>(
            future: _getLogCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  'Total sessions: ${snapshot.data}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareCurrentSession(BuildContext context) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final zipFile = await AppLogger.createCurrentSessionZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      // Share the zip file
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - Current Session Logs',
          text: 'Debug logs from current session',
          files: [XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  Future<void> _shareAllLogs(BuildContext context) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final zipFile = await AppLogger.createAllLogsZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      // Share the zip file
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - All Session Logs',
          text: 'Debug logs from all sessions',
          files: [XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  Future<int> _getLogCount() async {
    try {
      final logsDir = await AppLogger.logsDirectory;
      if (!await logsDir.exists()) return 0;

      final files = logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).length;

      return files;
    } catch (e) {
      return 0;
    }
  }

  String _maskMnemonic(String mnemonic) {
    final words = mnemonic.split(' ');
    if (words.length != 12) return '•••• •••• •••• •••• •••• •••• •••• •••• •••• •••• •••• ••••';
    
    // Show first 2 characters of each word, mask the rest
    return words.map((word) {
      if (word.length <= 2) return word;
      return '${word.substring(0, 2)}${'•' * (word.length - 2)}';
    }).join(' ');
  }

  void _showMnemonicDialog(BuildContext context, String mnemonic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Mnemonic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your wallet seed phrase (keep this secure):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                mnemonic,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Never share this with anyone!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangeMnemonicDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Mnemonic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter new mnemonic (12 words):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'word1 word2 word3 ... word12',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ This will disconnect and reconnect with the new wallet!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newMnemonic = controller.text.trim();
              if (newMnemonic.split(' ').length == 12) {
                ref.read(mnemonicProvider.notifier).setMnemonic(newMnemonic);
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mnemonic changed! Wallet will reconnect...'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid 12-word mnemonic'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
