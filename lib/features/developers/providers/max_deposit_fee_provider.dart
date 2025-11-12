import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/config_service.dart';

/// Notifier for max deposit claim fee
class MaxDepositClaimFeeNotifier extends Notifier<Fee> {
  @override
  Fee build() {
    final ConfigService configService = ref.watch(configServiceProvider);
    return configService.getMaxDepositClaimFee();
  }

  Future<void> setFee(Fee fee) async {
    final ConfigService configService = ref.read(configServiceProvider);
    await configService.setMaxDepositClaimFee(fee);
    state = fee;
  }

  Future<void> reset() async {
    final ConfigService configService = ref.read(configServiceProvider);
    await configService.resetMaxDepositClaimFee();
    state = configService.getMaxDepositClaimFee();
  }
}

/// Provider for max deposit claim fee
final NotifierProvider<MaxDepositClaimFeeNotifier, Fee> maxDepositClaimFeeProvider =
    NotifierProvider<MaxDepositClaimFeeNotifier, Fee>(MaxDepositClaimFeeNotifier.new);
