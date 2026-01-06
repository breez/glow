import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/settings/providers/biometrics_provider.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/providers/security_backup_notifier.dart';
import 'package:glow/features/settings/security_backup_layout.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/routing/app_routes.dart';

/// Container widget for Security & Backup screen
class SecurityBackupScreen extends ConsumerWidget {
  const SecurityBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPinEnabled = ref.watch(pinStatusProvider).value ?? false;
    final bool isBiometricsEnabled = ref.watch(biometricsEnabledProvider).value ?? false;
    final bool isBiometricsAvailable = ref.watch(biometricsAvailableProvider).value ?? false;
    final String biometricType = ref.watch(biometricTypeProvider).value ?? 'Biometrics';
    final bool isWalletVerified = ref.watch(activeWalletProvider).value?.isVerified ?? false;
    final int lockInterval = ref.watch(pinLockIntervalProvider).value ?? 5;

    final SecurityBackupNotifier notifier = ref.read(securityBackupNotifierProvider.notifier);

    return SecurityBackupLayout(
      isPinEnabled: isPinEnabled,
      isBiometricsEnabled: isBiometricsEnabled,
      isBiometricsAvailable: isBiometricsAvailable,
      biometricType: biometricType,
      isWalletVerified: isWalletVerified,
      onTogglePin: (bool enable) => _handleTogglePin(context, notifier, enable, isPinEnabled),
      onChangePin: () => Navigator.pushNamed(context, AppRoutes.pinSetup),
      onToggleBiometrics: (bool enable) => _handleToggleBiometrics(context, notifier, enable),
      onBackupPhrase: () => _handleBackupPhrase(context, ref, notifier),
      lockInterval: lockInterval,
      onLockIntervalChanged: (double value) => _handleLockIntervalChanged(notifier, value),
    );
  }

  Future<void> _handleTogglePin(
    BuildContext context,
    SecurityBackupNotifier notifier,
    bool enable,
    bool currentStatus,
  ) async {
    if (notifier.togglePin(enable, currentStatus)) {
      // Navigate to PIN setup and wait for result
      await Navigator.pushNamed(context, AppRoutes.pinSetup);
      // After returning from PIN setup, refresh the PIN status
      // This ensures the UI updates without requiring PIN verification again
    } else {
      // Deactivate happened, show feedback
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN deactivated'), backgroundColor: Colors.green));
    }
  }

  Future<void> _handleToggleBiometrics(
    BuildContext context,
    SecurityBackupNotifier notifier,
    bool enable,
  ) async {
    try {
      await notifier.toggleBiometrics(enable);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update biometrics: $e')));
      }
    }
  }

  Future<void> _handleBackupPhrase(
    BuildContext context,
    WidgetRef ref,
    SecurityBackupNotifier notifier,
  ) async {
    try {
      final ({String mnemonic, dynamic wallet}) result = await notifier.loadBackupPhrase();
      if (!context.mounted) {
        return;
      }

      Navigator.pushNamed(
        context,
        AppRoutes.walletPhrase,
        arguments: <String, dynamic>{'wallet': result.wallet, 'mnemonic': result.mnemonic},
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleLockIntervalChanged(SecurityBackupNotifier notifier, double seconds) async {
    try {
      await notifier.setLockInterval(seconds.toInt());
    } catch (e) {
      // Handle error
    }
  }
}
