import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:mockito/annotations.dart';

// Generate mocks by running: dart run build_runner build
@GenerateMocks([BreezSdk])
void main() {}

/// Test fixtures for common data
class TestFixtures {
  static Payment createTestPayment({String? id, PaymentType type = PaymentType.receive, BigInt? amount}) {
    return Payment(
      id: id ?? 'test_payment',
      paymentType: type,
      status: PaymentStatus.completed,
      amount: amount ?? BigInt.from(1000),
      fees: BigInt.zero,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      method: PaymentMethod.lightning,
      details: null,
    );
  }

  static GetInfoResponse createTestNodeInfo({BigInt? balance}) {
    return GetInfoResponse(balanceSats: balance ?? BigInt.from(100000), tokenBalances: {});
  }

  static ReceivePaymentResponse createTestInvoice({String? invoice, BigInt? fee}) {
    return ReceivePaymentResponse(paymentRequest: invoice ?? 'lnbc1000...', feeSats: fee ?? BigInt.zero);
  }
}
