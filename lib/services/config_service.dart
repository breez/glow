import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/config/breez_config.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final log = AppLogger.getLogger('ConfigService');

/// Service for managing persistent app configuration
class ConfigService {
  static const String _maxDepositClaimFeeTypeKey = 'max_deposit_claim_fee_type';
  static const String _maxDepositClaimFeeValueKey = 'max_deposit_claim_fee_value';

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
}

/// Provider for ConfigService
final configServiceProvider = Provider<ConfigService>((ref) {
  throw UnimplementedError('ConfigService must be overridden in main.dart with SharedPreferences');
});

/// Notifier for max deposit claim fee
class MaxDepositClaimFeeNotifier extends Notifier<Fee> {
  @override
  Fee build() {
    final configService = ref.watch(configServiceProvider);
    return configService.getMaxDepositClaimFee();
  }

  Future<void> setFee(Fee fee) async {
    final configService = ref.read(configServiceProvider);
    await configService.setMaxDepositClaimFee(fee);
    state = fee;
  }

  Future<void> reset() async {
    final configService = ref.read(configServiceProvider);
    await configService.resetMaxDepositClaimFee();
    state = configService.getMaxDepositClaimFee();
  }
}

/// Provider for max deposit claim fee
final maxDepositClaimFeeProvider = NotifierProvider<MaxDepositClaimFeeNotifier, Fee>(
  MaxDepositClaimFeeNotifier.new,
);
