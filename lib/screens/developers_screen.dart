import 'dart:io';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/app_routes.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/services/config_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:glow/providers/wallet_provider.dart';

class DevelopersScreen extends ConsumerWidget {
  const DevelopersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Wallet Management Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallets', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your wallets',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final walletCount = ref.watch(walletCountProvider);
                      return Text(
                        'Total wallets: $walletCount',
                        style: Theme.of(context).textTheme.bodyLarge,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.walletList);
                      },
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Manage Wallets'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Network Switch Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: network == Network.mainnet
                              ? null
                              : () {
                                  ref.read(networkProvider.notifier).setNetwork(Network.mainnet);
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
                              color: network == Network.mainnet
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
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
                                  ref.read(networkProvider.notifier).setNetwork(Network.regtest);
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
                              color: network == Network.regtest
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Max Deposit Claim Fee Card
          Card(
            child: InkWell(
              onTap: () => _showMaxFeeBottomSheet(context, ref, maxDepositClaimFee),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deposit Claim Fee', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                'Maximum fee when claiming deposits',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(Icons.speed, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            maxDepositClaimFee.when(
                              rate: (satPerVbyte) => '$satPerVbyte sat/vByte',
                              fixed: (amount) => '$amount sats',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logs Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logs', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Share logs for debugging',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.share),
                    title: const Text('Share Current Session'),
                    subtitle: const Text('Share logs from this session only'),
                    onTap: () => _shareCurrentSession(context),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_zip),
                    title: const Text('Share All Logs'),
                    subtitle: const Text('Share all session logs (last 10)'),
                    onTap: () => _shareAllLogs(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          FutureBuilder<int>(
            future: _getLogCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  'Total sessions: ${snapshot.data}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _showMaxFeeBottomSheet(BuildContext context, WidgetRef ref, Fee currentFee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MaxFeeBottomSheet(
        currentFee: currentFee,
        onSave: (fee) async {
          try {
            await ref.read(maxDepositClaimFeeProvider.notifier).setFee(fee);

            // Invalidate SDK to reconnect with new fee
            ref.invalidate(sdkProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Fee updated.'), duration: Duration(seconds: 2)));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
        onReset: () async {
          await ref.read(maxDepositClaimFeeProvider.notifier).reset();
          ref.invalidate(sdkProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reset to default.'), duration: Duration(seconds: 2)),
            );
          }
        },
      ),
    );
  }

  Future<void> _shareCurrentSession(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final zipFile = await AppLogger.createCurrentSessionZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - Current Session Logs',
          text: 'Debug logs from current session',
          files: [XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  Future<void> _shareAllLogs(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final zipFile = await AppLogger.createAllLogsZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - All Session Logs',
          text: 'Debug logs from all sessions',
          files: [XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  Future<int> _getLogCount() async {
    try {
      final logsDir = await AppLogger.logsDirectory;
      if (!await logsDir.exists()) return 0;

      final files = logsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.log')).length;

      return files;
    } catch (e) {
      return 0;
    }
  }
}

class _MaxFeeBottomSheet extends StatefulWidget {
  final Fee currentFee;
  final Function(Fee) onSave;
  final VoidCallback onReset;

  const _MaxFeeBottomSheet({required this.currentFee, required this.onSave, required this.onReset});

  @override
  State<_MaxFeeBottomSheet> createState() => _MaxFeeBottomSheetState();
}

class _MaxFeeBottomSheetState extends State<_MaxFeeBottomSheet> {
  late bool _useFixedFee;
  late double _sliderValue;

  // Predefined rate options (1-10 sat/vByte)
  static const double _minRate = 1.0;
  static const double _maxRate = 10.0;

  // Predefined fixed fee options (100-1000 sats)
  static const double _minFixed = 100.0;
  static const double _maxFixed = 1000.0;

  // Conversion factor: assuming ~100 vBytes for a typical transaction
  static const double _conversionFactor = 100.0;

  @override
  void initState() {
    super.initState();
    _useFixedFee = widget.currentFee.when(rate: (_) => false, fixed: (_) => true);
    _sliderValue = widget.currentFee.when(
      rate: (rate) => rate.toDouble(),
      fixed: (amount) => amount.toDouble(),
    );
  }

  // Convert rate to fixed fee
  double _rateToFixed(double rate) {
    return (rate * _conversionFactor).floorToDouble().clamp(_minFixed, _maxFixed);
  }

  // Convert fixed fee to rate
  double _fixedToRate(double fixedFee) {
    return (fixedFee / _conversionFactor).floorToDouble().clamp(_minRate, _maxRate);
  }

  Fee get _currentFee {
    final rate = BigInt.from(_sliderValue.round());
    if (_useFixedFee) {
      return Fee.fixed(amount: rate);
    } else {
      return Fee.rate(satPerVbyte: rate);
    }
  }

  String get _feeDescription {
    final rate = _sliderValue.round();
    if (_useFixedFee) {
      return '$rate sats fixed';
    } else {
      final estimatedFee = (_conversionFactor * rate).round();
      return '$rate sat/vByte (~$estimatedFee sats)';
    }
  }

  String get _speedLabel {
    if (_useFixedFee) {
      if (_sliderValue < 300) return 'Economy';
      if (_sliderValue < 500) return 'Standard';
      if (_sliderValue < 800) return 'Fast';
      return 'Priority';
    } else {
      if (_sliderValue < 2) return 'Economy';
      if (_sliderValue < 4) return 'Standard';
      if (_sliderValue < 7) return 'Fast';
      return 'Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              children: [
                // Title
                Text(
                  'Deposit Claim Fee',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the maximum fee for claiming Bitcoin deposits',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),

                const SizedBox(height: 32),

                // Current fee display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _speedLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _feeDescription,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Fee type toggle
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToggleButton(
                          label: 'Rate',
                          isSelected: !_useFixedFee,
                          onTap: () {
                            setState(() {
                              // Convert current fixed fee to rate
                              final newRate = _fixedToRate(_sliderValue);
                              _useFixedFee = false;
                              _sliderValue = newRate;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _ToggleButton(
                          label: 'Fixed',
                          isSelected: _useFixedFee,
                          onTap: () {
                            setState(() {
                              // Convert current rate to fixed fee
                              final newFixed = _rateToFixed(_sliderValue);
                              _useFixedFee = true;
                              _sliderValue = newFixed;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Slider
                Column(
                  children: [
                    Slider(
                      activeColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.75),
                      thumbColor: Theme.of(context).primaryColorLight,
                      value: _sliderValue,
                      min: _useFixedFee ? _minFixed : _minRate,
                      max: _useFixedFee ? _maxFixed : _maxRate,
                      divisions: _useFixedFee ? 18 : 9,
                      label: _feeDescription,
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _useFixedFee ? '${_minFixed.round()} sats' : '${_minRate.floor()} sat/vB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _useFixedFee ? '${_maxFixed.round()} sats' : '${_maxRate.floor()} sat/vB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Higher fees ensure deposits are claimed during network congestion',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onReset();
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).primaryColorLight),
                        onPressed: () {
                          widget.onSave(_currentFee);
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
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

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColorLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
