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

  group('Payments Provider Integration Tests', () {
    late MockBreezSdk mockSdk;
    late StreamController<SdkEvent> eventController;

    setUp(() {
      mockSdk = MockBreezSdk();
      eventController = StreamController<SdkEvent>.broadcast();

      // Setup default mocks
      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo());

      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: []));

      when(mockSdk.addEventListener()).thenAnswer((_) => eventController.stream);
    });

    tearDown(() {
      eventController.close();
    });

    test('allPaymentsProvider fetches payments from SDK', () async {
      // Arrange
      final testPayment = TestFixtures.createTestPayment(amount: BigInt.from(5000));
      when(
        mockSdk.listPayments(request: argThat(isA<ListPaymentsRequest>(), named: 'request')),
      ).thenAnswer((_) async => ListPaymentsResponse(payments: [testPayment]));

      final container = createMockedContainer(mockSdk: mockSdk);

      // Act
      final payments = await waitForProvider(container, allPaymentsProvider);

      // Assert
      expect(payments, hasLength(1));
      expect(payments.first.amount, BigInt.from(5000));
    });

    test('balance provider returns correct balance', () async {
      // Arrange
      when(
        mockSdk.getInfo(request: argThat(isA<GetInfoRequest>(), named: 'request')),
      ).thenAnswer((_) async => TestFixtures.createTestNodeInfo(balance: BigInt.from(50000)));

      final container = createMockedContainer(mockSdk: mockSdk);

      // Act
      final nodeInfo = await waitForProvider(container, nodeInfoProvider);
      final balanceValue = container.read(balanceProvider).value;

      // Assert
      expect(nodeInfo.balanceSats, BigInt.from(50000));
      expect(balanceValue, BigInt.from(50000));
    });
  });

  group('Payment Events Integration', () {
    late MockBreezSdk mockSdk;
    late StreamController<SdkEvent> eventController;

    setUp(() {
      mockSdk = MockBreezSdk();
      eventController = StreamController<SdkEvent>.broadcast();

      when(mockSdk.addEventListener()).thenAnswer((_) => eventController.stream);
    });

    tearDown(() {
      eventController.close();
    });

    test('paymentSuccessEventsProvider emits on payment', () async {
      // Arrange
      final container = createMockedContainer(mockSdk: mockSdk);
      final payment = TestFixtures.createTestPayment(amount: BigInt.from(2000));

      // Start listening
      final completer = Completer<Payment>();
      final subscription = container.listen(paymentSuccessEventsProvider, (previous, next) {
        if (next.hasValue && !completer.isCompleted) {
          completer.complete(next.value!);
        }
      }, fireImmediately: true);

      await Future.delayed(Duration(milliseconds: 50));
      eventController.add(SdkEvent.paymentSucceeded(payment: payment));

      final receivedPayment = await completer.future.timeout(Duration(seconds: 2));
      subscription.close();
      expect(receivedPayment.amount, BigInt.from(2000));
    });
  });
}
