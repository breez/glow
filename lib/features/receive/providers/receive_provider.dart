import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/models/receive_state.dart';

class ReceiveNotifier extends Notifier<ReceiveState> {
  @override
  ReceiveState build() => ReceiveState.initial();

  void changeMethod(ReceiveMethod method) =>
      state = state.copyWith(method: method, isLoading: false, hasError: false);

  void setLoading() => state = state.copyWith(isLoading: true);

  void setError(String error) => state = state.copyWith(hasError: true, error: error);
}

final NotifierProvider<ReceiveNotifier, ReceiveState> receiveProvider =
    NotifierProvider<ReceiveNotifier, ReceiveState>(ReceiveNotifier.new);
