import 'package:equatable/equatable.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:glow/features/receive/models/receive_method.dart';

enum AmountInputFlowStep { initial, inputAmount, displayPayment, paymentReceived }

class ReceiveState extends Equatable {
  const ReceiveState({
    required this.method,
    required this.isLoading,
    required this.hasError,
    this.error,
    this.flowStep = AmountInputFlowStep.initial,
    this.amountSats,
    this.receivePaymentResponse,
  });

  final ReceiveMethod method;
  final bool isLoading;
  final bool hasError;
  final String? error;
  final AmountInputFlowStep flowStep;
  final BigInt? amountSats;
  final ReceivePaymentResponse? receivePaymentResponse;

  /// Default receive method: lightning
  factory ReceiveState.initial() =>
      const ReceiveState(method: ReceiveMethod.lightning, isLoading: false, hasError: false);

  factory ReceiveState.loading(ReceiveMethod method) =>
      ReceiveState(method: method, isLoading: true, hasError: false);

  factory ReceiveState.error(ReceiveMethod method, String error) =>
      ReceiveState(method: method, isLoading: false, hasError: true, error: error);

  ReceiveState copyWith({
    ReceiveMethod? method,
    bool? isLoading,
    bool? hasError,
    String? error,
    AmountInputFlowStep? flowStep,
    BigInt? amountSats,
    ReceivePaymentResponse? receivePaymentResponse,
  }) {
    return ReceiveState(
      method: method ?? this.method,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      error: error ?? this.error,
      flowStep: flowStep ?? this.flowStep,
      amountSats: amountSats ?? this.amountSats,
      receivePaymentResponse: receivePaymentResponse ?? this.receivePaymentResponse,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    method,
    isLoading,
    hasError,
    error,
    flowStep,
    amountSats,
    receivePaymentResponse,
  ];
}
