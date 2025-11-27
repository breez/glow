import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/widgets/balance/balance_display.dart';
import 'package:glow/features/home/widgets/home_app_bar.dart';
import 'package:glow/features/home/widgets/home_bottom_bar.dart';
import 'package:glow/features/home/widgets/home_drawer.dart';
import 'package:glow/features/home/widgets/qr_scan_button.dart';
import 'package:glow/features/home/widgets/transaction_filter/transaction_filter_provider.dart';
import 'package:glow/features/home/widgets/transaction_filter/transaction_filter_view.dart';
import 'package:glow/features/home/widgets/transaction_filter/widgets/active_filters_view.dart';
import 'package:glow/features/home/widgets/transactions/transaction_list.dart';

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

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (BuildContext context, Widget? child) {
        final double balanceHeight;
        final double filterHeight;

        // When a filter is active, the balance shrinks and filter controls are locked open.
        if (hasActiveFilter) {
          balanceHeight = balanceMinHeight;
          filterHeight = filterMaxHeight;
        } else {
          // Otherwise, animate based on scroll position.
          final double offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
          balanceHeight = max(
            balanceMinHeight,
            (balanceMaxHeight - offset).clamp(balanceMinHeight, balanceMaxHeight),
          );
          filterHeight = offset.clamp(0.0, filterMaxHeight);
        }

        return Scaffold(
          appBar: const HomeAppBar(),
          bottomNavigationBar: const HomeBottomBar(),
          drawerDragStartBehavior: DragStartBehavior.down,
          drawerEdgeDragWidth: MediaQuery.of(context).size.width,
          drawer: const HomeDrawer(),
          floatingActionButton: const QrScanButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                SizedBox(height: balanceHeight, child: const BalanceDisplay()),
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
