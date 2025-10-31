import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/app_routes.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/widgets/home/balance_display.dart';
import 'package:glow/widgets/home/home_app_bar.dart';
import 'package:glow/widgets/home/home_bottom_bar.dart';
import 'package:glow/widgets/home/home_drawer.dart';
import 'package:glow/widgets/home/qr_scan_button.dart';
import 'package:glow/widgets/home/transaction_list.dart';
import 'package:glow/widgets/unclaimed_deposits_warning.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);

    // Ensure SDK events are always being listened to
    ref.watch(sdkEventListenerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: themeData.bottomAppBarTheme.color,
      ),
      child: Scaffold(
        appBar: const HomeAppBar(),
        bottomNavigationBar: const HomeBottomBar(),
        body: Column(
          children: [
            UnclaimedDepositsWarning(onTap: () => Navigator.pushNamed(context, AppRoutes.unclaimedDeposits)),
            const BalanceDisplay(),
            const Expanded(child: TransactionList()),
          ],
        ),
        drawerDragStartBehavior: DragStartBehavior.down,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        drawer: const HomeDrawer(),
        floatingActionButton: const QrScanButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
