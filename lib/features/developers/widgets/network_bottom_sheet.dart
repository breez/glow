import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';

class NetworkBottomSheet extends StatelessWidget {
  final Network currentNetwork;
  final Function(Network) onNetworkChanged;

  const NetworkBottomSheet({
    required this.currentNetwork,
    required this.onNetworkChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title
                Text(
                  'Switch Network',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch between mainnet and regtest',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                // Network options
                Card(
                  child: RadioGroup<Network>(
                    groupValue: currentNetwork,
                    onChanged: (Network? value) {
                      if (value != null) {
                        onNetworkChanged(value);
                        Navigator.pop(context);
                      }
                    },
                    child: Column(
                      children: <Widget>[
                        _NetworkOption(
                          network: Network.mainnet,
                          label: 'Mainnet',
                          selectedNetwork: currentNetwork,
                          onTap: () {
                            onNetworkChanged(Network.mainnet);
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(height: 1),
                        _NetworkOption(
                          network: Network.regtest,
                          label: 'Regtest',
                          selectedNetwork: currentNetwork,
                          onTap: () {
                            onNetworkChanged(Network.regtest);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkOption extends StatelessWidget {
  final Network network;
  final String label;
  final Network selectedNetwork;
  final VoidCallback onTap;

  const _NetworkOption({
    required this.network,
    required this.label,
    required this.selectedNetwork,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = network == selectedNetwork;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Radio<Network>(value: network),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            if (isSelected) Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
