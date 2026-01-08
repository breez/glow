import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/widgets/card_wrapper.dart';

class NetworkMismatchError extends StatelessWidget {
  final Network currentNetwork;
  final BitcoinNetwork addressNetwork;

  const NetworkMismatchError({
    required this.currentNetwork,
    required this.addressNetwork,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String currentNetworkName = currentNetwork == Network.mainnet ? 'Mainnet' : 'Testnet';
    final String addressNetworkName = addressNetwork == BitcoinNetwork.bitcoin
        ? 'Mainnet'
        : 'Testnet';

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error_outline, color: colorScheme.error, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Network Mismatch',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This payment is intended for $addressNetworkName, but you are currently connected to $currentNetworkName.',
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
