import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/bip21_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('Bip21Notifier');

/// Provider for BIP21 unified payment state
///
/// This provider manages the state for BIP21 payments with multiple payment methods
final NotifierProviderFamily<Bip21Notifier, Bip21State, Bip21Details> bip21Provider =
    NotifierProvider.autoDispose.family<Bip21Notifier, Bip21State, Bip21Details>(Bip21Notifier.new);

/// Notifier for BIP21 payment flow
class Bip21Notifier extends Notifier<Bip21State> {
  Bip21Notifier(this.arg);
  final Bip21Details arg;

  @override
  Bip21State build() {
    // Start with the list of available payment methods
    return Bip21Initial(paymentMethods: arg.paymentMethods);
  }

  /// Select a payment method
  void selectMethod(InputType method) {
    _log.i('Selected payment method: ${method.runtimeType}');
    state = Bip21MethodSelected(selectedMethod: method);
  }
}
