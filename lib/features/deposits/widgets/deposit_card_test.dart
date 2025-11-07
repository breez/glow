import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/providers/deposit_claimer.dart';
import 'package:glow/features/deposits/widgets/deposit_card.dart';
import 'package:glow/features/deposits/models/unclaimed_deposits_state.dart';
import 'package:glow/features/deposits/widgets/deposit_error_banner.dart';

void main() {
  group('DepositCard', () {
    // Helper function to create mock DepositInfo
    DepositInfo createMockDeposit({
      String? txid,
      int? vout,
      required BigInt amountSats,
      DepositClaimError? claimError,
      String? refundTx,
      String? refundTxId,
    }) {
      return DepositInfo(
        txid: txid ?? 'test_txid_${DateTime.now().millisecondsSinceEpoch}',
        vout: vout ?? 0,
        amountSats: amountSats,
        claimError: claimError,
        refundTx: refundTx,
        refundTxId: refundTxId,
      );
    }

    DepositCardData cardDataFromDeposit(DepositInfo deposit) {
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
    }

    // Helper to create DepositCard widget from DepositInfo
    Widget makeDepositCard(
      DepositInfo deposit, {
      Key? cardKey,
      VoidCallback? onRetryClaim,
      VoidCallback? onShowRefundInfo,
      VoidCallback? onCopyTxid,
    }) {
      final cardData = cardDataFromDeposit(deposit);
      return DepositCard(
        key: cardKey,
        deposit: cardData.deposit,
        hasError: cardData.hasError,
        hasRefund: cardData.hasRefund,
        formattedTxid: cardData.formattedTxid,
        formattedErrorMessage: cardData.formattedErrorMessage,
        onRetryClaim: onRetryClaim ?? () {},
        onShowRefundInfo: onShowRefundInfo ?? () {},
        onCopyTxid: onCopyTxid ?? () {},
      );
    }

    // Helper to wrap widget with MaterialApp and ProviderScope
    Widget makeTestable(Widget child) {
      return ProviderScope(
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    group('initial state (collapsed)', () {
      final testCases = [
        {
          'desc': 'shows deposit amount',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.text('10000 sats'), findsOneWidget);
          },
        },
        {
          'desc': 'shows "Waiting to claim" status when no error',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.text('Waiting to claim'), findsOneWidget);
          },
        },
        {
          'desc': 'shows "Failed to claim" status when error exists',
          'deposit': createMockDeposit(
            amountSats: BigInt.from(10000),
            claimError: DepositClaimError.generic(message: 'Test error'),
          ),
          'expect': (WidgetTester tester) async {
            expect(find.text('Failed to claim'), findsOneWidget);
          },
        },
        {
          'desc': 'shows expand icon when collapsed',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.byIcon(Icons.expand_more), findsOneWidget);
            expect(find.byIcon(Icons.expand_less), findsNothing);
          },
        },
        {
          'desc': 'shows wallet icon',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
          },
        },
        {
          'desc': 'does not show transaction details when collapsed',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000), txid: 'test_transaction_id'),
          'expect': (WidgetTester tester) async {
            expect(find.text('Transaction'), findsNothing);
            expect(find.text('Output'), findsNothing);
            expect(find.text('Retry Claim'), findsNothing);
          },
        },
      ];
      for (final tc in testCases) {
        testWidgets(tc['desc'] as String, (tester) async {
          final deposit = tc['deposit'] as DepositInfo;
          await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
          await (tc['expect'] as Function)(tester);
        });
      }
    });

    group('expanded state', () {
      testWidgets('expands when tapped', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.text('Transaction'), findsOneWidget);
      });

      testWidgets('shows transaction ID when expanded', (tester) async {
        final deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          txid: '1234567890abcdefghijklmnopqrstuvwxyz',
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.textContaining('12345678'), findsOneWidget);
        expect(find.textContaining('stuvwxyz'), findsOneWidget);
      });

      testWidgets('shows output index when expanded', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000), vout: 5);
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.text('Output'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows retry claim button when expanded', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.text('Retry Claim'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('shows divider when expanded', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.byType(Divider), findsOneWidget);
      });

      testWidgets('collapses when tapped again', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        final cardKey = Key('deposit_card_${deposit.txid}');
        await tester.pumpWidget(
          makeTestable(
            makeDepositCard(
              deposit,
              cardKey: cardKey,
              onRetryClaim: () {},
              onShowRefundInfo: () {},
              onCopyTxid: () {},
            ),
          ),
        );
        // Expand
        await tester.tap(find.byKey(cardKey));
        await tester.pumpAndSettle();
        expect(find.text('Transaction'), findsOneWidget);
        // Collapse
        await tester.tap(find.byKey(cardKey));
        await tester.pumpAndSettle();
        expect(find.text('Transaction'), findsNothing);
      });
    });
    group('error state', () {
      testWidgets('shows error banner when error exists', (tester) async {
        final deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          claimError: DepositClaimError.generic(message: 'Test error'),
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        // Expand to see error
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.byType(DepositErrorBanner), findsOneWidget);
      });

      testWidgets('shows error border color when error exists', (tester) async {
        final deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          claimError: DepositClaimError.generic(message: 'Test error'),
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape as RoundedRectangleBorder;
        // Error border should have some alpha (not fully transparent)
        expect(shape.side.color.alpha, greaterThan(0));
      });

      testWidgets('does not show error banner when no error', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.byType(DepositErrorBanner), findsNothing);
      });
    });

    group('refund transaction', () {
      testWidgets('shows refund button when refund exists', (tester) async {
        final deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          refundTx: 'refund_transaction_data',
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('View Refund'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('does not show refund button when no refund', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('View Refund'), findsNothing);
      });

      testWidgets('calls onShowRefundInfo when refund button tapped', (tester) async {
        bool callbackCalled = false;
        final deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          refundTx: 'refund_transaction_data',
        );
        await tester.pumpWidget(
          makeTestable(
            makeDepositCard(
              deposit,
              onShowRefundInfo: () {
                callbackCalled = true;
              },
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        await tester.tap(find.text('View Refund'));
        await tester.pumpAndSettle();

        expect(callbackCalled, true);
      });
    });

    group('callbacks', () {
      testWidgets('calls onRetryClaim when retry button tapped', (tester) async {
        bool callbackCalled = false;
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(
          makeTestable(
            makeDepositCard(
              deposit,
              onRetryClaim: () {
                callbackCalled = true;
              },
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Retry Claim'));
        await tester.pumpAndSettle();

        expect(callbackCalled, true);
      });
    });

    group('visual styling', () {
      testWidgets('uses Card widget', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('uses InkWell for tap feedback', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('has proper padding', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        // Find the Padding widget that wraps the content
        final padding = tester.widget<Padding>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(Padding)).first,
        );

        expect(padding.padding, const EdgeInsets.all(16));
      });
    });

    group('edge cases', () {
      testWidgets('handles very long transaction IDs', (tester) async {
        final deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          txid: 'a' * 100, // Very long txid
        );

        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Should show truncated version
        expect(find.textContaining('aaaaaaaa'), findsOneWidget);
      });

      testWidgets('handles very large amounts', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.from(99999999));

        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.text('99999999 sats'), findsOneWidget);
      });

      testWidgets('handles zero amount', (tester) async {
        final deposit = createMockDeposit(amountSats: BigInt.zero);

        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.text('0 sats'), findsOneWidget);
      });
    });
  });
}
