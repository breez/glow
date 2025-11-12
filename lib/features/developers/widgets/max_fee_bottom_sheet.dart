import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/developers/widgets/toggle_button.dart';

class MaxFeeBottomSheet extends StatefulWidget {
  final Fee currentFee;
  final Function(Fee) onSave;
  final VoidCallback onReset;

  const MaxFeeBottomSheet({required this.currentFee, required this.onSave, required this.onReset, super.key});

  @override
  State<MaxFeeBottomSheet> createState() => _MaxFeeBottomSheetState();
}

class _MaxFeeBottomSheetState extends State<MaxFeeBottomSheet> {
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
      rate: (BigInt rate) => rate.toDouble(),
      fixed: (BigInt amount) => amount.toDouble(),
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
    final BigInt rate = BigInt.from(_sliderValue.round());
    if (_useFixedFee) {
      return Fee.fixed(amount: rate);
    } else {
      return Fee.rate(satPerVbyte: rate);
    }
  }

  String get _feeDescription {
    final int rate = _sliderValue.round();
    if (_useFixedFee) {
      return '$rate sats fixed';
    } else {
      final int estimatedFee = (_conversionFactor * rate).round();
      return '$rate sat/vByte (~$estimatedFee sats)';
    }
  }

  String get _speedLabel {
    if (_useFixedFee) {
      if (_sliderValue < 300) {
        return 'Economy';
      }
      if (_sliderValue < 500) {
        return 'Standard';
      }
      if (_sliderValue < 800) {
        return 'Fast';
      }
      return 'Priority';
    } else {
      if (_sliderValue < 2) {
        return 'Economy';
      }
      if (_sliderValue < 4) {
        return 'Standard';
      }
      if (_sliderValue < 7) {
        return 'Fast';
      }
      return 'Priority';
    }
  }

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
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
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
                    children: <Widget>[
                      Expanded(
                        child: ToggleButton(
                          label: 'Rate',
                          isSelected: !_useFixedFee,
                          onTap: () {
                            setState(() {
                              // Convert current fixed fee to rate
                              final double newRate = _fixedToRate(_sliderValue);
                              _useFixedFee = false;
                              _sliderValue = newRate;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: ToggleButton(
                          label: 'Fixed',
                          isSelected: _useFixedFee,
                          onTap: () {
                            setState(() {
                              // Convert current rate to fixed fee
                              final double newFixed = _rateToFixed(_sliderValue);
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
                  children: <Widget>[
                    Slider(
                      activeColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.75),
                      thumbColor: Theme.of(context).primaryColorLight,
                      value: _sliderValue,
                      min: _useFixedFee ? _minFixed : _minRate,
                      max: _useFixedFee ? _maxFixed : _maxRate,
                      divisions: _useFixedFee ? 18 : 9,
                      label: _feeDescription,
                      onChanged: (double value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
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
                    children: <Widget>[
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
                  children: <Widget>[
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
