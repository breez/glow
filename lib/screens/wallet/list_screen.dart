import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/models/wallet_metadata.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/screens/wallet/setup_screen.dart';
import 'package:glow/services/wallet_storage_service.dart';
import 'package:glow/screens/wallet/verify_screen.dart';
import 'package:glow/screens/wallet/create_screen.dart';
import 'package:glow/screens/wallet/import_screen.dart';
import 'package:glow/widgets/wallet/empty_state.dart';

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
    for (var c in _editControllers.values) {
      c.dispose();
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
      setState(() => _editingWalletId = null);
    }
  }

  Future<void> _saveEdit(WalletMetadata wallet) async {
    final newName = _editControllers[wallet.id]?.text.trim() ?? '';

    if (newName.length < 2) {
      _showSnackBar('Name must be at least 2 characters', Colors.orange);
      return;
    }

    if (newName == wallet.name) {
      _cancelEditing();
      return;
    }

    try {
      await ref.read(walletListProvider.notifier).updateWalletName(wallet.id, newName);
      _cancelEditing();
      if (mounted) _showSnackBar('Renamed to "$newName"', Colors.green);
    } catch (e) {
      log.e('Failed to rename wallet', error: e);
      if (mounted) _showSnackBar('Failed to rename: $e', Colors.red);
    }
  }

  Future<void> _showVerification(WalletMetadata wallet) async {
    final mnemonic = await ref.read(walletStorageServiceProvider).loadMnemonic(wallet.id);

    if (mnemonic == null) {
      if (mounted) _showSnackBar('Failed to load mnemonic', Colors.red);
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletVerifyScreen(wallet: wallet, mnemonic: mnemonic),
        ),
      );
    }
  }

  Future<void> _switchWallet(WalletMetadata wallet) async {
    try {
      await ref.read(activeWalletProvider.notifier).switchWallet(wallet.id);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) _showSnackBar('Switched to ${wallet.name}', Colors.green);
        });
      }
    } catch (e) {
      log.e('Failed to switch wallet', error: e);
      if (mounted) _showSnackBar('Failed to switch: $e', Colors.red);
    }
  }

  Future<void> _removeWallet(WalletMetadata wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${wallet.name}?'),
        content: Text(
          'This will remove the wallet from the app. You can re-import it later using your recovery phrase.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(walletListProvider.notifier).deleteWallet(wallet.id);

      final wallets = ref.read(walletListProvider).value ?? [];
      final activeWallet = ref.read(activeWalletProvider).value;

      if (activeWallet?.id == wallet.id) {
        if (wallets.isNotEmpty) {
          await ref.read(activeWalletProvider.notifier).switchWallet(wallets.first.id);
        } else {
          await ref.read(activeWalletProvider.notifier).clearActiveWallet();
        }
      }

      if (mounted) _showSnackBar('Removed ${wallet.name}', Colors.orange);

      // Reroute if no wallets remain
      if (wallets.isEmpty && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WalletSetupScreen()));
      }
    } catch (e) {
      log.e('Failed to remove wallet', error: e);
      if (mounted) _showSnackBar('Failed to remove: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletListProvider);
    final activeWallet = ref.watch(activeWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wallets'),
        actions: [IconButton(icon: Icon(Icons.add), onPressed: () => _showAddWalletSheet())],
      ),
      body: wallets.when(
        data: (list) => list.isEmpty ? _buildEmptyState() : _buildWalletList(list, activeWallet.value),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(err),
      ),
    );
  }

  void _showAddWalletSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Create New Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => WalletCreateScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Import Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => WalletImportScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletList(List<WalletMetadata> wallets, WalletMetadata? active) {
    return ListView.builder(
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        final isActive = active?.id == wallet.id;
        final isEditing = _editingWalletId == wallet.id;

        return ListTile(
          title: isEditing
              ? TextField(
                  controller: _editControllers[wallet.id],
                  autofocus: true,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                )
              : Row(
                  children: [
                    Flexible(
                      child: Text(
                        wallet.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ],
                  ],
                ),
          trailing: isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _saveEdit(wallet),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: _cancelEditing,
                    ),
                  ],
                )
              : PopupMenuButton(
                  itemBuilder: (_) => [
                    if (!isActive)
                      PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [Icon(Icons.swap_horiz, size: 20), SizedBox(width: 12), Text('Switch')],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Rename')]),
                    ),
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 12),
                          Text('View phrase'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'switch':
                        _switchWallet(wallet);
                      case 'rename':
                        _startEditing(wallet);
                      case 'view':
                        _showVerification(wallet);
                      case 'remove':
                        _removeWallet(wallet);
                    }
                  },
                ),
          onTap: isActive || isEditing ? null : () => _switchWallet(wallet),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No Wallets',
      subtitle: 'Create a new wallet or import an existing one',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletCreateScreen())),
          icon: Icon(Icons.add),
          label: Text('Create Wallet'),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletImportScreen())),
          icon: Icon(Icons.download),
          label: Text('Import Wallet'),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to load wallets', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
