import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/screens/debug_screen.dart';
import 'package:glow/screens/payment_details_screen.dart';
import 'package:glow/screens/receive/receive_screen.dart';
import 'package:glow/screens/wallet/list_screen.dart';
import 'package:glow/screens/wallet/verify_screen.dart';
import 'package:glow/services/wallet_storage_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final payments = ref.watch(paymentsProvider);
    final activeWallet = ref.watch(activeWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              const Text('Glow'),
              const SizedBox(width: 8),
              // Show active wallet name
              activeWallet.when(
                data: (wallet) => wallet != null
                    ? GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WalletListScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(wallet.name, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          // Show warning icon for unverified wallets
          activeWallet.when(
            data: (wallet) => wallet != null && !wallet.isVerified
                ? IconButton(
                    onPressed: () async {
                      final mnemonic = await ref.read(walletStorageServiceProvider).loadMnemonic(wallet.id);
                      if (mnemonic != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WalletVerifyScreen(wallet: wallet, mnemonic: mnemonic),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    tooltip: 'Verify recovery phrase',
                  )
                : SizedBox.shrink(),
            loading: () => SizedBox.shrink(),
            error: (_, _) => SizedBox.shrink(),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DebugScreen()));
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
                onPressed: null,
                child: const Text('SEND', textAlign: TextAlign.center, maxLines: 1),
              ),
            ),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiveScreen()));
                },
                child: const Text('RECEIVE', textAlign: TextAlign.center, maxLines: 1),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Balance Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              children: [
                balance.when(
                  data: (sats) => Text(
                    _formatSats(sats),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  loading: () =>
                      const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
                  error: (err, _) => Text(
                    'Error loading',
                    style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.error),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'sats',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: payments.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 24,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final payment = list[index];
                      final isReceive = payment.paymentType == PaymentType.receive;

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PaymentDetailsScreen(payment: payment)),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isReceive ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isReceive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isReceive ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _getPaymentTitle(payment),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTimestamp(payment.timestamp),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isReceive ? '+' : '-'}${_formatSats(payment.amount)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(
                              height: 16,
                              child: payment.fees > BigInt.zero
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'fee ${_formatSats(payment.fees)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentTitle(Payment payment) {
    final details = payment.details;
    if (details == null) return 'Payment';

    return switch (details) {
      PaymentDetails_Spark() => 'Spark Payment',
      PaymentDetails_Token(:final metadata) => metadata.name,
      PaymentDetails_Lightning(:final description) =>
        description?.isNotEmpty == true ? description! : 'Lightning Payment',
      PaymentDetails_Withdraw() => 'Withdrawal',
      PaymentDetails_Deposit() => 'Deposit',
    };
  }

  String _formatSats(BigInt sats) {
    // Add thousand separators
    final str = sats.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      buffer.write(str[i]);
      final position = length - i - 1;
      if (position > 0 && position % 3 == 0) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  String _formatTimestamp(BigInt timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
