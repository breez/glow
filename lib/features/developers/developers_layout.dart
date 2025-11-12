import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/developers/widgets/logs_card.dart';
import 'package:glow/features/developers/widgets/max_deposit_claim_fee_card.dart';
import 'package:glow/features/developers/widgets/network_card.dart';
import 'package:glow/features/developers/widgets/wallet_card.dart';

class DevelopersLayout extends StatelessWidget {
  final Network network;
  final void Function(Network network) onChangeNetwork;
  final Fee maxDepositClaimFee;
  final VoidCallback onTapMaxFeeCard;
  final GestureTapCallback onShareCurrentSession;
  final GestureTapCallback onShareAllLogs;

  const DevelopersLayout({
    required this.network,
    required this.onChangeNetwork,
    required this.maxDepositClaimFee,
    required this.onTapMaxFeeCard,
    required this.onShareCurrentSession,
    required this.onShareAllLogs,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Wallet Management Card
          const WalletCard(),

          const SizedBox(height: 16),

          // Network Switch Card
          NetworkCard(network: network, onChangeNetwork: onChangeNetwork),

          const SizedBox(height: 16),

          // Max Deposit Claim Fee Card
          MaxDepositClaimFeeCard(currentFee: maxDepositClaimFee, onTapMaxFeeCard: onTapMaxFeeCard),

          const SizedBox(height: 16),

          // Logs Card
          LogsCard(onShareCurrentSession: onShareCurrentSession, onShareAllLogs: onShareAllLogs),
        ],
      ),
    );
  }
}
