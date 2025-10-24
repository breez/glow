import 'dart:io';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/screens/wallet_list_screen.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Wallet Management Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallets', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your wallets',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Wallet count
                  Consumer(
                    builder: (context, ref, _) {
                      final walletCount = ref.watch(walletCountProvider);
                      return Text(
                        'Total wallets: $walletCount',
                        style: Theme.of(context).textTheme.bodyLarge,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Manage wallets button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WalletListScreen()),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Manage Wallets'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                          child: Text(
                            'Mainnet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: network == Network.mainnet
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
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
                          child: Text(
                            'Regtest',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: network == Network.regtest
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
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
}
