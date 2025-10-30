import 'package:flutter/material.dart';

/// Empty state view when no Lightning Address is registered
class NoLightningAddressView extends StatelessWidget {
  final VoidCallback onRegister;

  const NoLightningAddressView({super.key, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alternate_email, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text('No Lightning Address', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Register a Lightning Address to receive payments easily',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: onRegister, child: const Text('Register Lightning Address')),
            const SizedBox(height: 16),
            Text(
              'Or use the + button to create an invoice',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
