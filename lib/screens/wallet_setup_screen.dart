import 'package:flutter/material.dart';
import 'package:glow/screens/wallet_create_screen.dart';
import 'package:glow/screens/wallet_import_screen.dart';

class WalletSetupScreen extends StatelessWidget {
  const WalletSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Spacer(flex: 30),
            Text('Glow', style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
            Spacer(flex: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => WalletCreateScreen())),
                      icon: Icon(Icons.add_circle_outline),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Create Wallet', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => WalletImportScreen())),
                      icon: Icon(Icons.download),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Import Wallet', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(flex: 30),
          ],
        ),
      ),
    );
  }
}
