import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';

class PaymentFilterDropdown extends StatelessWidget {
  final List<PaymentType> activeFilters;
  final Function(List<PaymentType>) onFilterChanged;

  const PaymentFilterDropdown(this.activeFilters, this.onFilterChanged, {super.key});

  static const String _all = 'All Activities';
  static const String _sent = 'Sent';
  static const String _received = 'Received';

  String _getSelection(List<PaymentType> filters) {
    if (filters.length != 1) {
      return _all;
    }
    switch (filters.first) {
      case PaymentType.send:
        return _sent;
      case PaymentType.receive:
        return _received;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _getSelection(activeFilters),
        dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
        iconEnabledColor: Colors.white,
        items: const <String>[_all, _sent, _received].map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? newValue) {
          final List<PaymentType> newFilters;
          switch (newValue) {
            case _sent:
              newFilters = <PaymentType>[PaymentType.send];
              break;
            case _received:
              newFilters = <PaymentType>[PaymentType.receive];
              break;
            default: // "All Activities"
              newFilters = <PaymentType>[]; // An empty list signifies all activities
              break;
          }
          onFilterChanged(newFilters);
        },
      ),
    );
  }
}
