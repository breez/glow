import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// Fee speed options for onchain transactions
enum FeeSpeed { slow, medium, fast }

/// State for Bitcoin Address (onchain) payment flows
sealed class BitcoinAddressState extends Equatable implements PaymentFlowState {
  const BitcoinAddressState();

  @override
  bool get isInitial => this is BitcoinAddressInitial;
  @override
  bool get isPreparing => this is BitcoinAddressPreparing;
  @override
  bool get isReady => this is BitcoinAddressReady;
  @override
  bool get isSending => this is BitcoinAddressSending;
  @override
  bool get isSuccess => this is BitcoinAddressSuccess;
  @override
  bool get isError => this is BitcoinAddressError;
  @override
  String? get errorMessage => this is BitcoinAddressError ? (this as BitcoinAddressError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - showing amount input
class BitcoinAddressInitial extends BitcoinAddressState {
  const BitcoinAddressInitial();
}

/// Preparing the payment (calculating fees) after amount is entered
class BitcoinAddressPreparing extends BitcoinAddressState {
  final BigInt amountSats;

  const BitcoinAddressPreparing({required this.amountSats});

  @override
  List<Object?> get props => <Object?>[amountSats];
}

/// Payment is prepared and ready to send with fee options
class BitcoinAddressReady extends BitcoinAddressState {
  final PrepareSendPaymentResponse prepareResponse;
  final BigInt amountSats;
  final SendOnchainFeeQuote feeQuote;
  final FeeSpeed selectedSpeed;

  const BitcoinAddressReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeQuote,
    this.selectedSpeed = FeeSpeed.medium,
  });

  /// Get the fee for the currently selected speed
  BigInt get selectedFeeSats {
    switch (selectedSpeed) {
      case FeeSpeed.slow:
        return feeQuote.speedSlow.userFeeSat + feeQuote.speedSlow.l1BroadcastFeeSat;
      case FeeSpeed.medium:
        return feeQuote.speedMedium.userFeeSat + feeQuote.speedMedium.l1BroadcastFeeSat;
      case FeeSpeed.fast:
        return feeQuote.speedFast.userFeeSat + feeQuote.speedFast.l1BroadcastFeeSat;
    }
  }

  /// Get fee for specific speed
  BigInt getFeeForSpeed(FeeSpeed speed) {
    switch (speed) {
      case FeeSpeed.slow:
        return feeQuote.speedSlow.userFeeSat + feeQuote.speedSlow.l1BroadcastFeeSat;
      case FeeSpeed.medium:
        return feeQuote.speedMedium.userFeeSat + feeQuote.speedMedium.l1BroadcastFeeSat;
      case FeeSpeed.fast:
        return feeQuote.speedFast.userFeeSat + feeQuote.speedFast.l1BroadcastFeeSat;
    }
  }

  BitcoinAddressReady copyWith({FeeSpeed? selectedSpeed}) {
    return BitcoinAddressReady(
      prepareResponse: prepareResponse,
      amountSats: amountSats,
      feeQuote: feeQuote,
      selectedSpeed: selectedSpeed ?? this.selectedSpeed,
    );
  }

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeQuote, selectedSpeed];
}

/// Sending the payment
class BitcoinAddressSending extends BitcoinAddressState {
  final PrepareSendPaymentResponse prepareResponse;
  final FeeSpeed selectedSpeed;

  const BitcoinAddressSending({required this.prepareResponse, required this.selectedSpeed});

  @override
  List<Object?> get props => <Object?>[prepareResponse, selectedSpeed];
}

/// Payment sent successfully
class BitcoinAddressSuccess extends BitcoinAddressState {
  final Payment payment;

  const BitcoinAddressSuccess({required this.payment});

  @override
  List<Object?> get props => <Object?>[payment];
}

/// Payment failed
class BitcoinAddressError extends BitcoinAddressState {
  final String message;
  final String? technicalDetails;

  const BitcoinAddressError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
