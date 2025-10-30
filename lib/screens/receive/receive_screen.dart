import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/screens/receive/lightning_receive_view.dart';
import 'package:glow/screens/receive/bitcoin_receive_view.dart';
import 'package:glow/widgets/receive/amount_input_sheet.dart';

enum ReceiveMethod {
  lightning('Lightning', Icons.flash_on),

  const ReceiveMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> with LoggerMixin {
  ReceiveMethod _selectedMethod = ReceiveMethod.lightning;

  void _showAmountInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AmountInputSheet(receiveMethod: _selectedMethod),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _ReceiveMethodDropdown(
          selectedMethod: _selectedMethod,
          onChanged: (method) {
            if (method != null) {
              setState(() => _selectedMethod = method);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Request Specific Amount',
            onPressed: _showAmountInput,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_selectedMethod) {
          ReceiveMethod.lightning => LightningReceiveView(),
        },
      ),
    );
  }
}

/// Dropdown menu for selecting receive method in AppBar title
class _ReceiveMethodDropdown extends StatelessWidget {
  final ReceiveMethod selectedMethod;
  final ValueChanged<ReceiveMethod?> onChanged;

  const _ReceiveMethodDropdown({required this.selectedMethod, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<ReceiveMethod>(
      value: selectedMethod,
      onChanged: onChanged,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.arrow_drop_down),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      dropdownColor: Theme.of(context).colorScheme.surface,
      items: ReceiveMethod.values.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(method.icon, size: 20), const SizedBox(width: 8), Text(method.label)],
          ),
        );
      }).toList(),
    );
  }
}
