import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

/// State for BIP21 unified payment flows
sealed class Bip21State extends Equatable {
  const Bip21State();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - showing payment methods to choose from
class Bip21Initial extends Bip21State {
  final List<InputType> paymentMethods;

  const Bip21Initial({required this.paymentMethods});

  @override
  List<Object?> get props => <Object?>[paymentMethods];
}

/// User selected a payment method - ready to proceed
class Bip21MethodSelected extends Bip21State {
  final InputType selectedMethod;

  const Bip21MethodSelected({required this.selectedMethod});

  @override
  List<Object?> get props => <Object?>[selectedMethod];
}
