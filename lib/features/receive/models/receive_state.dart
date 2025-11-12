import 'package:equatable/equatable.dart';
import 'package:glow/features/receive/models/receive_method.dart';

class ReceiveState extends Equatable {
  const ReceiveState({required this.method, required this.isLoading, required this.hasError, this.error});

  final ReceiveMethod method;
  final bool isLoading;
  final bool hasError;
  final String? error;

  /// Default receive method: lightning
  factory ReceiveState.initial() =>
      const ReceiveState(method: ReceiveMethod.lightning, isLoading: false, hasError: false);

  factory ReceiveState.loading(ReceiveMethod method) =>
      ReceiveState(method: method, isLoading: true, hasError: false);

  factory ReceiveState.error(ReceiveMethod method, String error) =>
      ReceiveState(method: method, isLoading: false, hasError: true, error: error);

  ReceiveState copyWith({ReceiveMethod? method, bool? isLoading, bool? hasError, String? error}) {
    return ReceiveState(
      method: method ?? this.method,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[method, isLoading, hasError, error];
}
