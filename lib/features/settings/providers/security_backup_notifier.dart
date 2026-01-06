// ignore_for_file: unused_result

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart' as l_auth_android;
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/services/pin_service.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet/services/wallet_storage_service.dart';

/// Business logic for Security & Backup screen
class SecurityBackupNotifier extends Notifier<void> {
  late final PinService _pinService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void build() {
    _pinService = ref.watch(pinServiceProvider);
  }

  /// Toggle PIN on/off - returns true if should navigate to PIN setup
  bool togglePin(bool enable, bool currentStatus) {
    if (enable && !currentStatus) {
      return true; // Signal to navigate
    } else if (!enable && currentStatus) {
      deactivatePin();
    }
    return false;
  }

  /// Toggle biometrics with authentication
  Future<void> toggleBiometrics(bool enable) async {
    try {
      if (enable && !await _authenticateWithBiometrics()) {
        return;
      }

      await _pinService.setBiometricsEnabled(enable);
      // ignore: unawaited_futures
      ref.refresh(biometricsEnabledProvider);
    } catch (e) {
      rethrow;
    }
  }

  /// Deactivate PIN and biometrics
  Future<void> deactivatePin() async {
    try {
      await _pinService.clearPin();
      await _pinService.setBiometricsEnabled(false);

      // ignore: unawaited_futures
      ref.refresh(pinStatusProvider);
      // ignore: unawaited_futures
      ref.refresh(biometricsEnabledProvider);
    } catch (e) {
      rethrow;
    }
  }

  /// Open backup phrase - returns mnemonic and wallet or throws
  Future<({String mnemonic, WalletMetadata wallet})> loadBackupPhrase() async {
    final WalletMetadata? wallet = await ref.read(activeWalletProvider.future);
    if (wallet == null) {
      throw 'No active wallet found';
    }

    final WalletStorageService storageService = ref.read(walletStorageServiceProvider);
    final String? mnemonic = await storageService.loadMnemonic(wallet.id);
    if (mnemonic == null) {
      throw 'Failed to load backup phrase';
    }

    return (mnemonic: mnemonic, wallet: wallet);
  }

  /// Update PIN lock interval (in seconds)
  Future<void> setLockInterval(int seconds) async {
    try {
      await _pinService.setLockInterval(seconds);
      // ignore: unawaited_futures
      ref.refresh(pinLockIntervalProvider);
    } catch (e) {
      rethrow;
    }
  }

  /// Authenticate with biometrics
  Future<bool> _authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable this setting',
        biometricOnly: true,
        authMessages: const <l_auth_android.AuthMessages>[
          l_auth_android.AndroidAuthMessages(),
          IOSAuthMessages(),
        ],
      );
    } catch (_) {
      return false;
    }
  }
}

/// Notifier provider for security backup
final NotifierProvider<SecurityBackupNotifier, void> securityBackupNotifierProvider =
    NotifierProvider<SecurityBackupNotifier, void>(SecurityBackupNotifier.new);
