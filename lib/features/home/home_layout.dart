import 'dart:math';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/balance/balance_display.dart';
import 'package:glow/features/home/widgets/home_app_bar.dart';
import 'package:glow/features/home/widgets/home_bottom_bar.dart';
import 'package:glow/features/home/widgets/home_drawer.dart';
import 'package:glow/features/home/widgets/qr_scan_button.dart';
import 'package:glow/features/transaction_filter/models/transaction_filter_state.dart';
import 'package:glow/features/transaction_filter/providers/transaction_filter_provider.dart';
import 'package:glow/features/transaction_filter/transaction_filter_view.dart';
import 'package:glow/features/transaction_filter/widgets/active_filters_view.dart';
import 'package:glow/features/transactions/transaction_list.dart';
import 'package:glow/providers/sdk_provider.dart';

class HomeLayout extends ConsumerStatefulWidget {
  const HomeLayout({super.key});

  @override
  ConsumerState<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends ConsumerState<HomeLayout> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double balanceMaxHeight = 200.0;
    const double balanceMinHeight = 70.0;
    const double filterMaxHeight = 64.0;

    final bool hasActiveFilter = ref.watch(
      transactionFilterProvider.select(
        (TransactionFilterState state) =>
            state.paymentTypes.isNotEmpty || state.startDate != null || state.endDate != null,
      ),
    );

    final AsyncValue<List<Payment>> payments = ref.watch(paymentsProvider);
    final bool hasTransactions = payments.maybeWhen(
      data: (List<Payment> data) => data.isNotEmpty,
      orElse: () => false,
    );

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (BuildContext context, Widget? child) {
        final double balanceHeight;
        final double filterHeight;
        final double scrollOffsetFactor;

        if (!hasTransactions) {
          balanceHeight = balanceMaxHeight;
          filterHeight = 0.0;
          scrollOffsetFactor = 0.0;
        } else if (hasActiveFilter) {
          // When a filter is active, the balance shrinks and filter controls are locked open.
          balanceHeight = balanceMinHeight;
          filterHeight = filterMaxHeight;
          scrollOffsetFactor = 1.0;
        } else {
          // Otherwise, animate based on scroll position.
          final double offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
          balanceHeight = max(
            balanceMinHeight,
            (balanceMaxHeight - offset).clamp(balanceMinHeight, balanceMaxHeight),
          );
          filterHeight = offset.clamp(0.0, filterMaxHeight);
          // Calculate scroll offset factor: 0.0 at top, 1.0 when fully scrolled
          final double maxScroll = balanceMaxHeight - balanceMinHeight;
          scrollOffsetFactor = (offset / maxScroll).clamp(0.0, 1.0);
        }

        return Scaffold(
          appBar: const HomeAppBar(),
          bottomNavigationBar: const HomeBottomBar(),
          drawerDragStartBehavior: DragStartBehavior.down,
          drawerEdgeDragWidth: MediaQuery.of(context).size.width,
          drawer: const HomeDrawer(),
          floatingActionButton: const QrScanButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: balanceHeight,
                  child: BalanceDisplay(scrollOffsetFactor: scrollOffsetFactor),
                ),
                SizedBox(height: filterHeight, child: const TransactionFilterView()),
                const ActiveFiltersView(),
                Expanded(child: TransactionList(scrollController: _scrollController)),
              ],
            ),
          ),
        );
      },
    );
  }
}
