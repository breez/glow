import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:glow_breez/providers/sdk_provider.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mock_sdk.dart';
import '../helpers/mock_sdk.mocks.dart';
import '../helpers/test_container.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    initializeTestEnvironment();
    await AppLogger.initialize();
  });

  group('Receive Payment Flow', () {
    late MockBreezSdk mockSdk;
    late StreamController<SdkEvent> eventController;

    setUp(() {
      mockSdk = MockBreezSdk();
      eventController = StreamController<SdkEvent>.broadcast();

      // Setup default mocks
      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo(balance: BigInt.from(100000)));

      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: []));

      when(mockSdk.addEventListener()).thenAnswer((_) => eventController.stream);
    });

    tearDown(() {
      eventController.close();
    });

    test('complete receive flow: generate invoice -> receive -> balance updates', () async {
      // Arrange
      when(
        mockSdk.receivePayment(request: argThat(isA<ReceivePaymentRequest>(), named: 'request')),
      ).thenAnswer((_) async {
        return TestFixtures.createTestInvoice(invoice: 'lnbc5000test', fee: BigInt.zero);
      });

      final container = createMockedContainer(mockSdk: mockSdk);

      // Step 1: Generate invoice
      final invoiceResponse = await container.read(
        receivePaymentProvider(
          ReceivePaymentRequest(
            paymentMethod: ReceivePaymentMethod.bolt11Invoice(
              description: 'Test payment',
              amountSats: BigInt.from(5000),
            ),
          ),
        ).future,
      );

      expect(invoiceResponse.paymentRequest, 'lnbc5000test');

      // Step 2: Get initial balance
      final initialInfo = await waitForProvider(container, nodeInfoProvider);
      final initialBalance = initialInfo.balanceSats;

      // Step 3: Simulate payment received
      final payment = TestFixtures.createTestPayment(amount: BigInt.from(5000), type: PaymentType.receive);

      // Update mocks to reflect new state
      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo(balance: initialBalance + BigInt.from(5000)));

      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: [payment]));

      // Emit event
      eventController.add(SdkEvent.paymentSucceeded(payment: payment));

      // Create a completer to wait for the refresh
      final completer = Completer<GetInfoResponse>();
      container.listen(nodeInfoProvider, (previous, next) {
        if (next.hasValue && next.value!.balanceSats == BigInt.from(105000)) {
          completer.complete(next.value!);
        }
      });

      final updatedInfo = await completer.future.timeout(Duration(seconds: 2));

      expect(updatedInfo.balanceSats, initialBalance + BigInt.from(5000));

      // Step 5: Verify payment in list
      container.invalidate(allPaymentsProvider);
      final payments = await waitForProvider(container, allPaymentsProvider);

      expect(payments, hasLength(1));
      expect(payments.first.paymentType, PaymentType.receive);
      expect(payments.first.amount, BigInt.from(5000));
    });
  });
}
