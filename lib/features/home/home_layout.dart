import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/home/widgets/balance/balance_display.dart';
import 'package:glow/features/home/widgets/transactions/transaction_list.dart';
import 'package:glow/features/home/widgets/home_app_bar.dart';
import 'package:glow/features/home/widgets/home_bottom_bar.dart';
import 'package:glow/features/home/widgets/home_drawer.dart';
import 'package:glow/features/home/widgets/qr_scan_button.dart';

/// Pure presentation widget
/// No providers, no navigation, no side effects
class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      bottomNavigationBar: const HomeBottomBar(),
      drawerDragStartBehavior: DragStartBehavior.down,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      drawer: const HomeDrawer(),
      floatingActionButton: const QrScanButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3 - kToolbarHeight,
              child: BalanceDisplay(),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7 - kToolbarHeight - kBottomNavigationBarHeight,
              child: TransactionList(),
            ),
          ],
        ),
      ),
    );
  }
}
