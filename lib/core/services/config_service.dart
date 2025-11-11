import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/config/breez_config.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final log = AppLogger.getLogger('ConfigService');

/// Service for managing persistent app configuration
class ConfigService {
  static const String _maxDepositClaimFeeTypeKey = 'max_deposit_claim_fee_type';
  static const String _maxDepositClaimFeeValueKey = 'max_deposit_claim_fee_value';
  static const String _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  ConfigService(this._prefs);

  /// Get the current max deposit claim fee
  /// Returns the persisted value or default if not set
  Fee getMaxDepositClaimFee() {
    final type = _prefs.getString(_maxDepositClaimFeeTypeKey);
    final value = _prefs.getString(_maxDepositClaimFeeValueKey);

    if (type == null || value == null) {
      log.d('No persisted max deposit claim fee, using default');
      return BreezConfig.defaultMaxDepositClaimFee;
    }

    try {
      final feeValue = BigInt.parse(value);
      if (type == 'rate') {
        log.d('Loaded max deposit claim fee: rate=$feeValue sat/vByte');
        return Fee.rate(satPerVbyte: feeValue);
      } else if (type == 'fixed') {
        log.d('Loaded max deposit claim fee: fixed=$feeValue sats');
        return Fee.fixed(amount: feeValue);
      }
    } catch (e) {
      log.e('Failed to parse persisted fee, using default: $e');
    }

    return BreezConfig.defaultMaxDepositClaimFee;
  }

  /// Set the max deposit claim fee and persist it
  Future<void> setMaxDepositClaimFee(Fee fee) async {
    final result = fee.when(
      rate: (satPerVbyte) async {
        await _prefs.setString(_maxDepositClaimFeeTypeKey, 'rate');
        await _prefs.setString(_maxDepositClaimFeeValueKey, satPerVbyte.toString());
        log.i('Saved max deposit claim fee: rate=$satPerVbyte sat/vByte');
      },
      fixed: (amount) async {
        await _prefs.setString(_maxDepositClaimFeeTypeKey, 'fixed');
        await _prefs.setString(_maxDepositClaimFeeValueKey, amount.toString());
        log.i('Saved max deposit claim fee: fixed=$amount sats');
      },
    );
    await result;
  }

  /// Reset to default fee
  Future<void> resetMaxDepositClaimFee() async {
    await _prefs.remove(_maxDepositClaimFeeTypeKey);
    await _prefs.remove(_maxDepositClaimFeeValueKey);
    log.i('Reset max deposit claim fee to default');
  }

  // TODO: This will be used for theme management in the future
  /// Get the current theme mode
  /// Returns the persisted value or system default if not set
  ThemeMode getThemeMode() {
    final saved = _prefs.getString(_themeModeKey);
    if (saved != null) {
      final mode = ThemeMode.values.firstWhere((e) => e.name == saved, orElse: () => ThemeMode.dark);
      log.d('Loaded theme mode: $mode');
      return mode;
    }
    log.d('No persisted theme mode, using dark as default');
    return ThemeMode.dark;
  }

  /// Set the theme mode and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
    log.i('Saved theme mode: $mode');
  }

  /// Reset to system default theme
  Future<void> resetThemeMode() async {
    await _prefs.remove(_themeModeKey);
    log.i('Reset theme mode to system default');
  }
}

/// Provider for ConfigService
final configServiceProvider = Provider<ConfigService>((ref) {
  throw UnimplementedError('ConfigService must be overridden in main.dart with SharedPreferences');
});
