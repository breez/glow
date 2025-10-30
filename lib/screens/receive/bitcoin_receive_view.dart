import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/bitcoin_address_provider.dart';
import 'package:glow/widgets/receive/qr_code_card.dart';
import 'package:glow/widgets/receive/copyable_card.dart';
import 'package:glow/widgets/receive/info_card.dart';
import 'package:glow/widgets/receive/error_view.dart';

/// Bitcoin receive view - displays on-chain Bitcoin address with QR code
class BitcoinReceiveView extends ConsumerWidget {
  const BitcoinReceiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bitcoinAddressAsync = ref.watch(bitcoinAddressProvider);

    return bitcoinAddressAsync.when(
      data: (address) =>
          address != null ? _BitcoinAddressContent(address: address) : const _NoBitcoinAddress(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorView(message: 'Failed to load Bitcoin address', error: err.toString()),
    );
  }
}

/// Content displayed for Bitcoin on-chain address
class _BitcoinAddressContent extends ConsumerWidget {
  final BitcoinAddressData address;

  const _BitcoinAddressContent({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          QRCodeCard(data: address.address),
          const SizedBox(height: 32),
          CopyableCard(title: 'Bitcoin Address', content: address.address),
          const SizedBox(height: 8),
          // Network indicator
          _NetworkBadge(network: address.network),
          const SizedBox(height: 16),
          const InfoCard(
            icon: Icons.info_outline,
            text: 'Bitcoin on-chain transactions may take 10-60 minutes to confirm',
          ),
        ],
      ),
    );
  }
}

/// Empty state when no Bitcoin address is available
class _NoBitcoinAddress extends ConsumerWidget {
  const _NoBitcoinAddress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGenerating = ref.watch(generateBitcoinAddressProvider(null).select((state) => state.isLoading));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.currency_bitcoin, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text('No Bitcoin Address', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Generate a Bitcoin address to receive on-chain payments',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: isGenerating
                  ? null
                  : () async {
                      await ref.read(generateBitcoinAddressProvider(null).future);
                    },
              icon: isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: Text(isGenerating ? 'Generating...' : 'Generate Bitcoin Address'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Network badge to show which Bitcoin network the address is for
class _NetworkBadge extends StatelessWidget {
  final BitcoinNetwork network;

  const _NetworkBadge({required this.network});

  @override
  Widget build(BuildContext context) {
    // Don't show badge for mainnet
    if (network == BitcoinNetwork.bitcoin) {
      return const SizedBox.shrink();
    }

    final networkName = _getNetworkName(network);
    final color = _getNetworkColor(context, network);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            networkName,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  String _getNetworkName(BitcoinNetwork network) {
    switch (network) {
      case BitcoinNetwork.bitcoin:
        return 'Mainnet';
      case BitcoinNetwork.testnet3:
        return 'Testnet3';
      case BitcoinNetwork.testnet4:
        return 'Testnet4';
      case BitcoinNetwork.signet:
        return 'Signet';
      case BitcoinNetwork.regtest:
        return 'Regtest';
    }
  }

  Color _getNetworkColor(BuildContext context, BitcoinNetwork network) {
    if (network == BitcoinNetwork.bitcoin) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.error;
  }
}
