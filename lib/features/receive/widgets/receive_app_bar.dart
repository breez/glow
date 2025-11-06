import 'package:flutter/material.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/models/receive_state.dart';

class ReceiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReceiveAppBar({
    super.key,
    required this.showAppBarControls,
    required this.state,
    required this.onChangeMethod,
    required this.onRequest,
  });

  final bool showAppBarControls;
  final ReceiveState state;
  final ValueChanged<ReceiveMethod> onChangeMethod;
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: showAppBarControls,
      title: showAppBarControls
          ? ReceiveMethodDropdown(selectedMethod: state.method, onChanged: onChangeMethod)
          : const Text('Receive'),
      actions: showAppBarControls ? [StaticAmountRequestIcon(showAmountInput: onRequest)] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Dropdown widget for selecting receive method
class ReceiveMethodDropdown extends StatelessWidget {
  final ReceiveMethod selectedMethod;
  final ValueChanged<ReceiveMethod> onChanged;

  const ReceiveMethodDropdown({super.key, required this.selectedMethod, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButton<ReceiveMethod>(
      value: selectedMethod,
      onChanged: (method) {
        if (method != null) onChanged(method);
      },
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.arrow_drop_down),
      style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface),
      dropdownColor: theme.colorScheme.surface,
      items: ReceiveMethod.values
          .map((method) => DropdownMenuItem(value: method, child: Text(method.label)))
          .toList(),
    );
  }
}

/// Icon button widget for requesting a specific amount payment
class StaticAmountRequestIcon extends StatelessWidget {
  final VoidCallback? showAmountInput;

  const StaticAmountRequestIcon({super.key, required this.showAmountInput});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      tooltip: 'Request Specific Amount',
      onPressed: showAmountInput,
    );
  }
}
