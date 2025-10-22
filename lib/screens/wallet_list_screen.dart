import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/logging/logger_mixin.dart';
import 'package:glow_breez/models/wallet_metadata.dart';
import 'package:glow_breez/providers/wallet_provider.dart';
import 'package:glow_breez/screens/wallet_backup_screen.dart';
import 'package:glow_breez/screens/wallet_create_screen.dart';
import 'package:glow_breez/screens/wallet_import_screen.dart';

/// Screen for managing multiple wallets
///
/// Features:
/// - List all wallets with metadata
/// - Switch between wallets
/// - Create new wallets
/// - Import existing wallets
/// - Rename wallets
/// - View backup status
/// - Delete wallets (with confirmation)
class WalletListScreen extends ConsumerStatefulWidget {
  const WalletListScreen({super.key});

  @override
  ConsumerState<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends ConsumerState<WalletListScreen> with LoggerMixin {
  String? _editingWalletId;
  final _editControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startEditing(WalletMetadata wallet) {
    setState(() {
      _editingWalletId = wallet.id;
      _editControllers[wallet.id] = TextEditingController(text: wallet.name);
    });
  }

  void _cancelEditing() {
    if (_editingWalletId != null) {
      _editControllers[_editingWalletId]?.dispose();
      _editControllers.remove(_editingWalletId);
    }
    setState(() {
      _editingWalletId = null;
    });
  }

  Future<void> _saveEdit(WalletMetadata wallet) async {
    final controller = _editControllers[wallet.id];
    if (controller == null) return;

    final newName = controller.text.trim();

    if (newName.isEmpty || newName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (newName == wallet.name) {
      _cancelEditing();
      return;
    }

    try {
      log.i('Renaming wallet: ${wallet.id} from "${wallet.name}" to "$newName"');

      await ref.read(walletListProvider.notifier).updateWalletName(wallet.id, newName);

      _cancelEditing();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Renamed to "$newName"'), backgroundColor: Colors.green));
    } catch (e, stack) {
      log.e('Failed to rename wallet', error: e, stackTrace: stack);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rename wallet: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showBackup(WalletMetadata wallet) async {
    final storage = ref.read(walletStorageServiceProvider);
    final mnemonic = await storage.loadMnemonic(wallet.id);

    if (mnemonic == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load wallet mnemonic'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WalletBackupScreen(wallet: wallet, mnemonic: mnemonic, isNewWallet: false),
      ),
    );
  }

  Future<void> _switchToWallet(WalletMetadata wallet) async {
    try {
      log.i('Switching to wallet: ${wallet.id} (${wallet.name})');

      await ref.read(activeWalletProvider.notifier).switchWallet(wallet.id);

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Switched to ${wallet.name}'), backgroundColor: Colors.green),
          );
        }
      });
    } catch (e, stack) {
      log.e('Failed to switch wallet', error: e, stackTrace: stack);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch wallet: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteWallet(WalletMetadata wallet) async {
    try {
      log.w('Deleting wallet: ${wallet.id} (${wallet.name})');

      await ref.read(walletListProvider.notifier).deleteWallet(wallet.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted ${wallet.name}'), backgroundColor: Colors.orange));
    } catch (e, stack) {
      log.e('Failed to delete wallet', error: e, stackTrace: stack);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete wallet: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletListProvider);
    final activeWallet = ref.watch(activeWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('Create New Wallet'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WalletCreateScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text('Import Wallet'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WalletImportScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            tooltip: 'Add Wallet',
          ),
        ],
      ),
      body: wallets.when(
        data: (list) {
          if (list.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final wallet = list[index];
              final isActive = activeWallet.value?.id == wallet.id;
              final isEditing = _editingWalletId == wallet.id;

              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.blue : Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: isActive ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                ),
                title: isEditing
                    ? TextField(
                        controller: _editControllers[wallet.id],
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _saveEdit(wallet),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              wallet.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                subtitle: isEditing
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              wallet.isBackedUp ? Icons.check_circle : Icons.warning_amber_rounded,
                              size: 14,
                              color: wallet.isBackedUp ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              wallet.isBackedUp ? 'Backed up' : 'Not backed up',
                              style: TextStyle(
                                fontSize: 13,
                                color: wallet.isBackedUp ? Colors.green : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              wallet.network.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                trailing: isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _saveEdit(wallet),
                            tooltip: 'Save',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: _cancelEditing,
                            tooltip: 'Cancel',
                          ),
                        ],
                      )
                    : PopupMenuButton(
                        itemBuilder: (context) => [
                          if (!isActive)
                            const PopupMenuItem(
                              value: 'switch',
                              child: Row(
                                children: [
                                  Icon(Icons.swap_horiz, size: 20),
                                  SizedBox(width: 12),
                                  Text('Switch to this wallet'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Rename')],
                            ),
                          ),
                          if (!wallet.isBackedUp)
                            const PopupMenuItem(
                              value: 'backup',
                              child: Row(
                                children: [Icon(Icons.backup, size: 20), SizedBox(width: 12), Text('Backup')],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 20),
                                SizedBox(width: 12),
                                Text('View recovery phrase'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'switch':
                              _switchToWallet(wallet);
                              break;
                            case 'rename':
                              _startEditing(wallet);
                              break;
                            case 'backup':
                              _showBackup(wallet);
                              break;
                            case 'view':
                              _showBackup(wallet);
                              break;
                            case 'delete':
                              _deleteWallet(wallet);
                              break;
                          }
                        },
                      ),
                onTap: isActive || isEditing ? null : () => _switchToWallet(wallet),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load wallets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text('No Wallets', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create a new wallet or import an existing one to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletCreateScreen()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Wallet'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletImportScreen()));
              },
              icon: const Icon(Icons.download),
              label: const Text('Import Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
