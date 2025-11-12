import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/receive/providers/receive_provider.dart';
import 'package:glow/features/receive/receive_layout.dart';
import 'package:glow/features/receive/widgets/amount_input_sheet.dart';

class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReceiveState state = ref.watch(receiveProvider);
    final ReceiveNotifier notifier = ref.read(receiveProvider.notifier);

    return ReceiveLayout(
      state: state,
      onChangeMethod: notifier.changeMethod,
      onRequest: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => AmountInputSheet(receiveMethod: state.method),
        );
      },
    );
  }
}
