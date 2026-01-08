import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Reusable PIN entry widget with numeric pad
class PinEntryWidget extends StatefulWidget {
  final int pinLength;
  final ValueChanged<String> onPinComplete;
  final VoidCallback onInputStarted;
  final String label;
  final String? errorMessage;

  const PinEntryWidget({
    required this.onPinComplete,
    required this.label,
    required this.onInputStarted,
    this.pinLength = 6,
    this.errorMessage,
    super.key,
  });

  @override
  State<PinEntryWidget> createState() => _PinEntryWidgetState();
}

class _PinEntryWidgetState extends State<PinEntryWidget> {
  String _pin = '';
  void _onNumberPressed(String number) {
    if (_pin.length < widget.pinLength) {
      if (_pin.isEmpty) {
        widget.onInputStarted.call();
      }
      setState(() {
        _pin += number;
      });

      if (_pin.length == widget.pinLength) {
        widget.onPinComplete(_pin);
      }
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _PinLabel(label: widget.label),
              _PinDotsDisplay(pinLength: widget.pinLength, currentLength: _pin.length),
              _ErrorMessageDisplay(errorMessage: widget.errorMessage),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: _NumericPad(
            onNumberPressed: _onNumberPressed,
            onBackspacePressed: _onBackspacePressed,
            onDeletePressed: _onDeletePressed,
          ),
        ),
      ],
    );
  }
}

class _PinLabel extends StatelessWidget {
  final String label;

  const _PinLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Displays the PIN dots that fill as user enters digits
class _PinDotsDisplay extends StatelessWidget {
  final int pinLength;
  final int currentLength;

  const _PinDotsDisplay({required this.pinLength, required this.currentLength});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(
          pinLength,
          (int index) => _PinDot(isFilled: index < currentLength),
        ),
      ),
    );
  }
}

/// Individual PIN dot indicator
class _PinDot extends StatelessWidget {
  final bool isFilled;

  const _PinDot({required this.isFilled});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFilled ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          border: Border.all(color: isFilled ? colorScheme.primary : colorScheme.outline, width: 2),
        ),
      ),
    );
  }
}

/// Displays error message with fixed height to prevent UI jumps
class _ErrorMessageDisplay extends StatelessWidget {
  final String? errorMessage;

  const _ErrorMessageDisplay({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                errorMessage!,
                style: TextStyle(fontSize: 14.3, color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }
}

/// Numeric keypad with 0-9, backspace, and delete buttons
class _NumericPad extends StatelessWidget {
  final ValueChanged<String> onNumberPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onDeletePressed;

  const _NumericPad({
    required this.onNumberPressed,
    required this.onBackspacePressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double verticalSpacing = 12;
        const double horizontalPadding = 12;
        const double minButtonSize = 56;
        const double maxButtonSize = 72;

        final double availableHeight = math.max(0, constraints.maxHeight - (verticalSpacing * 3));
        final double availableWidth = math.max(0, constraints.maxWidth - (horizontalPadding * 2));

        final double heightBasedSize = availableHeight / 4;
        final double widthBasedSize = availableWidth / 3;
        final double resolvedSize = heightBasedSize.isFinite && widthBasedSize.isFinite
            ? math.min(
                maxButtonSize,
                math.max(minButtonSize, math.min(heightBasedSize, widthBasedSize)),
              )
            : maxButtonSize;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _NumericPadRow(
                numbers: const <String>['1', '2', '3'],
                onNumberPressed: onNumberPressed,
                buttonSize: resolvedSize,
              ),
              const SizedBox(height: verticalSpacing),
              _NumericPadRow(
                numbers: const <String>['4', '5', '6'],
                onNumberPressed: onNumberPressed,
                buttonSize: resolvedSize,
              ),
              const SizedBox(height: verticalSpacing),
              _NumericPadRow(
                numbers: const <String>['7', '8', '9'],
                onNumberPressed: onNumberPressed,
                buttonSize: resolvedSize,
              ),
              const SizedBox(height: verticalSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _DeleteButton(onPressed: onDeletePressed, size: resolvedSize),
                  _NumberButton(number: '0', onPressed: onNumberPressed, size: resolvedSize),
                  _BackspaceButton(onPressed: onBackspacePressed, size: resolvedSize),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Row of number buttons in the numeric pad
class _NumericPadRow extends StatelessWidget {
  final List<String> numbers;
  final ValueChanged<String> onNumberPressed;
  final double buttonSize;

  const _NumericPadRow({
    required this.numbers,
    required this.onNumberPressed,
    required this.buttonSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: numbers
          .map(
            (String number) =>
                _NumberButton(number: number, onPressed: onNumberPressed, size: buttonSize),
          )
          .toList(),
    );
  }
}

/// Individual number button (0-9)
class _NumberButton extends StatelessWidget {
  final String number;
  final ValueChanged<String> onPressed;
  final double size;

  const _NumberButton({required this.number, required this.onPressed, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: size,
        height: size,
        child: ElevatedButton(
          onPressed: () => onPressed(number),
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            backgroundColor: Theme.of(context).canvasColor,
          ),
          child: Text(
            number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20.0),
          ),
        ),
      ),
    );
  }
}

/// Backspace button to delete last digit
class _BackspaceButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const _BackspaceButton({required this.onPressed, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton(onPressed: onPressed, icon: const Icon(Icons.backspace), iconSize: 20),
      ),
    );
  }
}

/// Delete button to clear all digits
class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const _DeleteButton({required this.onPressed, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.delete_forever),
          iconSize: 20,
        ),
      ),
    );
  }
}
