import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';

class NetworkSelector extends StatelessWidget {
  final Network selectedNetwork;
  final ValueChanged<Network> onChanged;

  const NetworkSelector({super.key, required this.selectedNetwork, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Network', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        RadioGroup<Network>(
          groupValue: selectedNetwork,
          onChanged: (v) => onChanged(v!),
          child: Card(
            child: Column(
              children: <Widget>[
                _NetworkOption(
                  network: Network.mainnet,
                  label: 'Mainnet',
                  onTap: () => onChanged(Network.mainnet),
                ),
                Divider(height: 1),
                _NetworkOption(
                  network: Network.regtest,
                  label: 'Regtest',
                  onTap: () => onChanged(Network.regtest),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkOption extends StatelessWidget {
  final Network network;
  final String label;
  final VoidCallback onTap;

  const _NetworkOption({required this.network, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap,
      child: Row(
        children: [
          Radio<Network>(value: network),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
