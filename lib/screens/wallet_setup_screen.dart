import 'package:flutter/material.dart';
import 'package:glow_breez/screens/wallet_create_screen.dart';
import 'package:glow_breez/screens/wallet_import_screen.dart';

/// First screen shown when no wallets exist
///
/// Allows user to choose between creating new wallet or importing existing one
class WalletSetupScreen extends StatelessWidget {
  const WalletSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Welcome Text
              Text(
                'Welcome to Glow',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Get started by creating a new wallet or importing an existing one',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Create New Wallet Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WalletCreateScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Create New Wallet', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Import Existing Wallet Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WalletImportScreen()),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Import Existing Wallet', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Info Card
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your wallet is secured with a 12-word recovery phrase. Keep it safe!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
