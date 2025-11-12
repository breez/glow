import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkCard extends ConsumerWidget {
  final Network network;
  final void Function(Network network) onChangeNetwork;

  const NetworkCard({required this.network, required this.onChangeNetwork, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Network', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Switch between mainnet and regtest',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: network == Network.mainnet
                        ? null
                        : () {
                            onChangeNetwork(Network.mainnet);
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: network == Network.mainnet
                          ? Theme.of(context).primaryColorLight
                          : null,
                      foregroundColor: network == Network.mainnet
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    child: Text(
                      'Mainnet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: network == Network.mainnet ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: network == Network.regtest
                        ? null
                        : () {
                            onChangeNetwork(Network.regtest);
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: network == Network.regtest
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: network == Network.regtest
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    child: Text(
                      'Regtest',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: network == Network.regtest ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
