import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/providers/sdk_provider.dart';

/// Creates a ProviderContainer for integration tests
///
/// Usage:
/// ```dart
/// test('balance updates on payment', () async {
///   final container = createTestContainer();
///
///   // Watch provider
///   final balance = container.read(balanceProvider);
///
///   // Trigger action
///   await container.read(receivePaymentProvider(...).future);
///
///   // Verify
///   expect(balance.value, greaterThan(0));
///
///   container.dispose();
/// });
/// ```
ProviderContainer createTestContainer({List<Override>? overrides}) {
  final container = ProviderContainer(overrides: overrides ?? []);

  // Automatically dispose after test
  addTearDown(container.dispose);

  return container;
}

/// Creates a container with mocked SDK
ProviderContainer createMockedContainer({required BreezSdk mockSdk, List<Override>? additionalOverrides}) {
  return createTestContainer(
    overrides: [sdkProvider.overrideWithValue(AsyncValue.data(mockSdk)), ...?additionalOverrides],
  );
}

/// Helper to wait for a provider to complete
Future<T> waitForProvider<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final completer = Completer<T>();

  final subscription = container.listen(provider, (previous, next) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.value!);
    } else if (next.hasError && !completer.isCompleted) {
      completer.completeError(next.error!, next.stackTrace!);
    }
  }, fireImmediately: true);

  try {
    return await completer.future.timeout(timeout);
  } finally {
    subscription.close();
  }
}
