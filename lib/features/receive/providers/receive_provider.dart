import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/services/breez_sdk_service.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/providers/sdk_provider.dart';

class ReceiveNotifier extends Notifier<ReceiveState> {
  @override
  ReceiveState build() => ReceiveState.initial();

  void changeMethod(ReceiveMethod method) => state = state.copyWith(
    method: method,
    isLoading: false,
    hasError: false,
    flowStep: AmountInputFlowStep.initial,
  );

  void setLoading() => state = state.copyWith(isLoading: true);

  void setError(String error) => state = state.copyWith(hasError: true, error: error);

  /// Initiate amount input flow
  void startAmountInput() {
    state = state.copyWith(flowStep: AmountInputFlowStep.inputAmount, hasError: false);
  }

  /// Store amount and transition to payment display
  Future<void> generatePaymentRequest(BigInt amount, {String description = 'Payment'}) async {
    state = state.copyWith(amountSats: amount, flowStep: AmountInputFlowStep.displayPayment, isLoading: true);

    try {
      if (state.method == ReceiveMethod.lightning) {
        final ReceivePaymentResponse response = await ref.watch(
          receivePaymentProvider(
            ReceivePaymentRequest(
              paymentMethod: ReceivePaymentMethod.bolt11Invoice(description: description, amountSats: amount),
            ),
          ).future,
        );
        state = state.copyWith(receivePaymentResponse: response, isLoading: false);
      }
      // Bitcoin address handling is done via provider watchers in UI layer
    } catch (err) {
      state = state.copyWith(hasError: true, error: err.toString(), isLoading: false);
    }
  }

  /// Reset to initial view (close amount input modal/screen)
  void resetAmountFlow() {
    state = state.copyWith(flowStep: AmountInputFlowStep.initial, hasError: false);
  }

  /// Go back one step in the flow
  void goBackInFlow() {
    if (state.flowStep == AmountInputFlowStep.displayPayment) {
      state = state.copyWith(flowStep: AmountInputFlowStep.inputAmount);
    } else if (state.flowStep == AmountInputFlowStep.inputAmount) {
      resetAmountFlow();
    }
  }
}

final NotifierProvider<ReceiveNotifier, ReceiveState> receiveProvider =
    NotifierProvider<ReceiveNotifier, ReceiveState>(ReceiveNotifier.new);

/// Generate payment request
final FutureProviderFamily<ReceivePaymentResponse, ReceivePaymentRequest> receivePaymentProvider =
    FutureProvider.autoDispose.family<ReceivePaymentResponse, ReceivePaymentRequest>((
      Ref ref,
      ReceivePaymentRequest request,
    ) async {
      log.d('receivePaymentProvider called with request: ${request.paymentMethod}');
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);
      final ReceivePaymentResponse response = await service.receivePayment(sdk, request);
      log.d('Payment request generated: ${response.paymentRequest}');
      return response;
    });
