/// Interface for all payment states to ensure common properties are available
/// for generic widgets like PaymentBottomNav.
abstract interface class PaymentFlowState {
  bool get isInitial;
  bool get isPreparing;
  bool get isReady;
  bool get isSending;
  bool get isSuccess;
  bool get isError;
  String? get errorMessage;
}
