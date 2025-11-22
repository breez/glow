import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DevelopersMenuButton extends StatelessWidget {
  final VoidCallback? onManageWallets;
  final VoidCallback? onShowNetworkSelector;
  final VoidCallback? onShowMaxFee;

  const DevelopersMenuButton({
    this.onManageWallets,
    this.onShowNetworkSelector,
    this.onShowMaxFee,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[];

    // Manage Wallets - debug only
    if (kDebugMode && onManageWallets != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'wallets',
          child: Row(
            children: <Widget>[
              Icon(Icons.account_balance_wallet, size: 20),
              SizedBox(width: 12),
              Text('Manage Wallets'),
            ],
          ),
        ),
      );
    }

    // Network - debug only
    if (kDebugMode && onShowNetworkSelector != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'network',
          child: Row(
            children: <Widget>[
              Icon(Icons.swap_horiz, size: 20),
              SizedBox(width: 12),
              Text('Network'),
            ],
          ),
        ),
      );
    }

    // Deposit Claim Fee - available in both debug and release
    if (onShowMaxFee != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'max_fee',
          child: Row(
            children: <Widget>[
              Icon(Icons.speed, size: 20),
              SizedBox(width: 12),
              Text('Deposit Claim Fee'),
            ],
          ),
        ),
      );
    }

    // Don't show menu if no items
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      onSelected: (String value) {
        switch (value) {
          case 'wallets':
            onManageWallets?.call();
            break;
          case 'network':
            onShowNetworkSelector?.call();
            break;
          case 'max_fee':
            onShowMaxFee?.call();
            break;
        }
      },
      itemBuilder: (BuildContext context) => items,
    );
  }
}

