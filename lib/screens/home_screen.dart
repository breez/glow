import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/widgets/home/balance_display.dart';
import 'package:glow/widgets/home/home_app_bar.dart';
import 'package:glow/widgets/home/home_bottom_bar.dart';
import 'package:glow/widgets/home/transaction_list.dart';
import 'package:glow/widgets/unclaimed_deposits_warning.dart';
import 'package:glow/screens/unclaimed_deposits_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure SDK events are always being listened to
    ref.watch(sdkEventListenerProvider);

    return Scaffold(
      appBar: const HomeAppBar(),
      bottomNavigationBar: const HomeBottomBar(),
      body: Column(
        children: [
          UnclaimedDepositsWarning(onTap: () => _navigateToUnclaimedDeposits(context)),
          const BalanceDisplay(),
          const Expanded(child: TransactionList()),
        ],
      ),
    );
  }

  void _navigateToUnclaimedDeposits(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UnclaimedDepositsScreen()));
  }
}
