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

  group('Payments Provider', () {
    late MockBreezSdk mockSdk;
    late StreamController<SdkEvent> eventController;

    setUp(() {
      mockSdk = MockBreezSdk();
      eventController = StreamController<SdkEvent>.broadcast();

      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo());

      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: []));

      when(mockSdk.addEventListener()).thenAnswer((_) => eventController.stream);
    });

    tearDown(() => eventController.close());

    test('fetches payments from SDK', () async {
      final testPayment = TestFixtures.createTestPayment(amount: BigInt.from(5000));
      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: [testPayment]));

      final container = createMockedContainer(mockSdk: mockSdk);
      final payments = await waitForProvider(container, paymentsProvider);

      expect(payments, hasLength(1));
      expect(payments.first.amount, BigInt.from(5000));
    });

    test('returns correct balance', () async {
      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo(balance: BigInt.from(50000)));

      final container = createMockedContainer(mockSdk: mockSdk);
      final nodeInfo = await waitForProvider(container, nodeInfoProvider);
      final balance = container.read(balanceProvider).value;

      expect(nodeInfo.balanceSats, BigInt.from(50000));
      expect(balance, BigInt.from(50000));
    });

    test('emits payment success events', () async {
      final container = createMockedContainer(mockSdk: mockSdk);
      final payment = TestFixtures.createTestPayment(amount: BigInt.from(2000));

      final completer = Completer<Payment>();
      final subscription = container.listen(sdkEventsProvider, (_, next) {
        if (next.hasValue && next.value is SdkEvent_PaymentSucceeded) {
          final event = next.value as SdkEvent_PaymentSucceeded;
          if (!completer.isCompleted) {
            completer.complete(event.payment);
          }
        }
      }, fireImmediately: true);

      await Future.delayed(Duration(milliseconds: 50));
      eventController.add(SdkEvent.paymentSucceeded(payment: payment));

      final received = await completer.future.timeout(Duration(seconds: 2));
      subscription.close();

      expect(received.amount, BigInt.from(2000));
    });
  });
}
