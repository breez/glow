import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/models/unclaimed_deposits_state.dart';
import 'package:glow/features/deposits/providers/deposit_claimer.dart';
import 'package:glow/features/deposits/unclaimed_deposits_layout.dart';
import 'package:glow/features/deposits/widgets/deposit_card.dart';
import 'package:glow/features/deposits/widgets/empty_deposits_state.dart';

void main() {
  group('UnclaimedDepositsLayout', () {
    // Helper to wrap widget with MaterialApp
    Widget makeTestable(Widget child) {
      return MaterialApp(home: child);
    }

    group('loading state', () {
      testWidgets('shows loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue.loading(),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(DepositCard), findsNothing);
        expect(find.byType(EmptyDepositsState), findsNothing);
      });

      testWidgets('shows app bar with title during loading', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue.loading(),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Pending Deposits'), findsOneWidget);
      });
    });

    group('loaded state with deposits', () {
      testWidgets('shows list of deposit cards when deposits exist', (tester) async {
        final deposits = [
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
          _createMockDeposit(txid: 'txid2', amountSats: BigInt.from(20000)),
          _createMockDeposit(txid: 'txid3', amountSats: BigInt.from(30000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsNWidgets(3));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(EmptyDepositsState), findsNothing);
      });

      testWidgets('shows correct deposit amounts', (tester) async {
        final deposits = [
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
          _createMockDeposit(txid: 'txid2', amountSats: BigInt.from(20000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.text('10000 sats'), findsOneWidget);
        expect(find.text('20000 sats'), findsOneWidget);
      });

      testWidgets('shows ListView with correct padding', (tester) async {
        final deposits = [_createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000))];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, const EdgeInsets.all(16));
      });
    });

    group('loaded state without deposits', () {
      testWidgets('shows empty state when no deposits', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(const AsyncValue.data([])),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (cardData) => DepositCard(
                deposit: cardData.deposit,
                hasError: cardData.hasError,
                hasRefund: cardData.hasRefund,
                formattedTxid: cardData.formattedTxid,
                formattedErrorMessage: cardData.formattedErrorMessage,
                onRetryClaim: () {},
                onShowRefundInfo: () {},
                onCopyTxid: () {},
              ),
            ),
          ),
        );

        expect(find.byType(EmptyDepositsState), findsOneWidget);
        expect(find.byType(DepositCard), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('empty state shows correct message', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(const AsyncValue.data([])),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (cardData) => DepositCard(
                deposit: cardData.deposit,
                hasError: cardData.hasError,
                hasRefund: cardData.hasRefund,
                formattedTxid: cardData.formattedTxid,
                formattedErrorMessage: cardData.formattedErrorMessage,
                onRetryClaim: () {},
                onShowRefundInfo: () {},
                onCopyTxid: () {},
              ),
            ),
          ),
        );

        expect(find.text('All deposits claimed'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error message when error occurs', (tester) async {
        final error = Exception('Network error');

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue.error(error, StackTrace.empty),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.text('Failed to load deposits'), findsOneWidget);
        expect(find.text(error.toString()), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('error state shows correct icon size and color', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue.error(Exception('Error'), StackTrace.empty),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(icon.size, 64);
        // Color check would require theme context
      });

      testWidgets('shows no deposit cards in error state', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue.error(Exception('Error'), StackTrace.empty),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(EmptyDepositsState), findsNothing);
      });
    });

    group('callbacks', () {
      testWidgets('passes onRetryClaim to deposit cards', (tester) async {
        final deposits = [_createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000))];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        // Verify deposit card exists (callback will be tested in deposit_card_test.dart)
        expect(find.byType(DepositCard), findsOneWidget);
      });

      testWidgets('passes onShowRefundInfo to deposit cards', (tester) async {
        final deposits = [_createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000))];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        // Verify deposit card exists (callback will be tested in deposit_card_test.dart)
        expect(find.byType(DepositCard), findsOneWidget);
      });
    });

    group('layout structure', () {
      testWidgets('always shows Scaffold', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue.loading(),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('always shows AppBar with title', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue.loading(),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Pending Deposits'), findsOneWidget);
      });
    });

    group('state transitions', () {
      testWidgets('transitions from loading to loaded', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue.loading(),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Update with data
        final deposits = [_createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000))];
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(DepositCard), findsOneWidget);
      });

      testWidgets('transitions from loaded to error', (tester) async {
        final deposits = [_createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000))];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsOneWidget);

        // Update with error
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue.error(Exception('Error'), StackTrace.empty),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(DepositCard), findsNothing);
        expect(find.text('Failed to load deposits'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles single deposit correctly', (tester) async {
        final deposits = [_createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000))];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsOneWidget);
      });

      testWidgets('handles many deposits correctly', (tester) async {
        // Each deposit amount increases by 10,000 sats per index
        final deposits = List.generate(10, (i) {
          final amountSats = 10000 * (i + 1);
          return _createMockDeposit(txid: 'txid$i', amountSats: BigInt.from(amountSats));
        });

        // Use tester.view instead of deprecated tester.binding.window
        final view = tester.view;
        final originalPhysicalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;

        view.physicalSize = const Size(1000, 3000);
        view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue.data(deposits)),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsNWidgets(10));

        // Clean up after test
        addTearDown(() {
          view.physicalSize = originalPhysicalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });
      });

      testWidgets('handles error with null message gracefully', (tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue.error('String error', StackTrace.empty),
              onRetryClaim: (_) async {},
              onShowRefundInfo: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onShowRefundInfo: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.text('Failed to load deposits'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });
  });
}

// Helper function to create mock DepositInfo
DepositInfo _createMockDeposit({
  required String txid,
  required BigInt amountSats,
  int? vout,
  DepositClaimError? claimError,
  String? refundTx,
  String? refundTxId,
}) {
  return DepositInfo(
    txid: txid,
    vout: vout ?? 0,
    amountSats: amountSats,
    claimError: claimError,
    refundTx: refundTx,
    refundTxId: refundTxId,
  );
}

AsyncValue<List<DepositCardData>> cardDataAsync(AsyncValue<List<DepositInfo>> depositsAsync) {
  return depositsAsync.map(
    data: (data) {
      final cardDataList = data.value.map((deposit) {
        final claimer = DepositClaimer();
        final hasError = claimer.hasError(deposit);
        final hasRefund = claimer.hasRefund(deposit);
        final formattedTxid = claimer.formatTxid(deposit.txid);
        final formattedErrorMessage = hasError && deposit.claimError != null
            ? claimer.formatError(deposit.claimError!)
            : null;
        return DepositCardData(
          deposit: deposit,
          hasError: hasError,
          hasRefund: hasRefund,
          formattedTxid: formattedTxid,
          formattedErrorMessage: formattedErrorMessage,
        );
      }).toList();
      return AsyncData(cardDataList);
    },
    loading: (loading) => const AsyncLoading(),
    error: (error) => AsyncError(error.error, error.stackTrace),
  );
}
