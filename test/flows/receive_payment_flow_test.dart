import 'dart:async';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mock_sdk.dart';
import '../helpers/mock_sdk.mocks.dart';
import '../helpers/test_container.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });

  group('Receive Payment Flow', () {
    late MockBreezSdk mockSdk;
    late StreamController<SdkEvent> eventController;

    setUp(() {
      mockSdk = MockBreezSdk();
      eventController = StreamController<SdkEvent>.broadcast();

      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo(balance: BigInt.from(100000)));

      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: []));

      when(mockSdk.addEventListener()).thenAnswer((_) => eventController.stream);
    });

    tearDown(() => eventController.close());

    test('generate invoice -> receive -> balance updates', () async {
      when(
        mockSdk.receivePayment(request: argThat(isA<ReceivePaymentRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestInvoice(invoice: 'lnbc5000test', fee: BigInt.zero));

      final container = createMockedContainer(mockSdk: mockSdk);

      // Generate invoice
      final invoice = await container.read(
        receivePaymentProvider(
          ReceivePaymentRequest(
            paymentMethod: ReceivePaymentMethod.bolt11Invoice(
              description: 'Test payment',
              amountSats: BigInt.from(5000),
            ),
          ),
        ).future,
      );

      expect(invoice.paymentRequest, 'lnbc5000test');

      // Get initial balance
      final initialInfo = await waitForProvider(container, nodeInfoProvider);
      final initialBalance = initialInfo.balanceSats;

      // Simulate payment received
      final payment = TestFixtures.createTestPayment(amount: BigInt.from(5000), type: PaymentType.receive);

      // Update mocks for new state
      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo(balance: initialBalance + BigInt.from(5000)));

      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: [payment]));

      // Emit payment event
      eventController.add(SdkEvent.paymentSucceeded(payment: payment));

      // Wait for balance update
      final completer = Completer<GetInfoResponse>();
      container.listen(nodeInfoProvider, (_, next) {
        if (next.hasValue && next.value!.balanceSats == BigInt.from(105000)) {
          completer.complete(next.value!);
        }
      });

      final updated = await completer.future.timeout(Duration(seconds: 2));
      expect(updated.balanceSats, initialBalance + BigInt.from(5000));

      // Verify payment in list
      container.invalidate(paymentsProvider);
      final payments = await waitForProvider(container, paymentsProvider);

      expect(payments, hasLength(1));
      expect(payments.first.paymentType, PaymentType.receive);
      expect(payments.first.amount, BigInt.from(5000));
    });
  });
}
