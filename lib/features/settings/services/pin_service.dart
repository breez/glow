import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glow/config/environment.dart';
import 'package:glow/logging/logger_mixin.dart';

/// Manages secure storage and verification of app PIN.
class PinService with LoggerMixin {
  /// Storage Key for PIN hash
  static const String _pinHashKey = 'app_pin_hash';

  /// Secure Storage Options
  static const String _accountName = 'Glow';
  static const KeychainAccessibility _keychainAccessibility = KeychainAccessibility.first_unlock;

  /// Get environment-aware storage configuration
  static FlutterSecureStorage _createStorage() {
    final Environment env = Environment.current;
    final String suffix = env.storageSuffix;

    return FlutterSecureStorage(
      aOptions: AndroidOptions(
        sharedPreferencesName: 'glow_prefs$suffix',
        preferencesKeyPrefix: 'glow${suffix}_',
        resetOnError: true,
      ),
      iOptions: IOSOptions(
        accountName: '$_accountName$suffix',
        accessibility: _keychainAccessibility,
      ),
      mOptions: MacOsOptions(
        accountName: '$_accountName$suffix',
        accessibility: _keychainAccessibility,
      ),
    );
  }

  final FlutterSecureStorage _storage = _createStorage();

  /// Hash a PIN using SHA-256
  String _hashPin(String pin) {
    final List<int> bytes = utf8.encode(pin);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if a PIN is set
  Future<bool> hasPin() async {
    try {
      final String? hash = await _storage.read(key: _pinHashKey);
      return hash != null && hash.isNotEmpty;
    } catch (e, stack) {
      log.e('Failed to check PIN status', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Set a new PIN
  Future<void> setPin(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 6) {
        throw ArgumentError('PIN must be between 4 and 6 digits');
      }

      final String hash = _hashPin(pin);
      await _storage.write(key: _pinHashKey, value: hash);
      log.i('PIN set successfully');
    } catch (e, stack) {
      log.e('Failed to set PIN', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Verify a PIN against the stored hash
  Future<bool> verifyPin(String pin) async {
    try {
      final String? storedHash = await _storage.read(key: _pinHashKey);
      if (storedHash == null || storedHash.isEmpty) {
        log.w('No PIN set, verification failed');
        return false;
      }

      final String inputHash = _hashPin(pin);
      final bool matches = inputHash == storedHash;
      log.d('PIN verification ${matches ? 'succeeded' : 'failed'}');
      return matches;
    } catch (e, stack) {
      log.e('Failed to verify PIN', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Clear the stored PIN
  Future<void> clearPin() async {
    try {
      await _storage.delete(key: _pinHashKey);
      log.i('PIN cleared successfully');
    } catch (e, stack) {
      log.e('Failed to clear PIN', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Check if biometrics is enabled
  Future<bool> isBiometricsEnabled() async {
    try {
      final String? value = await _storage.read(key: 'biometrics_enabled');
      return value == 'true';
    } catch (e, stack) {
      log.e('Failed to check biometrics status', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Set biometrics enabled state
  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'biometrics_enabled', value: enabled.toString());
      log.i('Biometrics enabled set to $enabled');
    } catch (e, stack) {
      log.e('Failed to set biometrics status', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get PIN lock interval (minutes)
  Future<int> getLockInterval() async {
    try {
      final String? value = await _storage.read(key: 'pin_lock_interval');
      return int.tryParse(value ?? '') ?? 5; // Default 5 minutes
    } catch (e, stack) {
      log.e('Failed to get lock interval', error: e, stackTrace: stack);
      return 5;
    }
  }

  /// Set PIN lock interval (minutes)
  Future<void> setLockInterval(int minutes) async {
    try {
      await _storage.write(key: 'pin_lock_interval', value: minutes.toString());
      log.i('Lock interval set to $minutes minutes');
    } catch (e, stack) {
      log.e('Failed to set lock interval', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
