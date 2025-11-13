import 'package:flutter/material.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/receive/widgets/receive_app_bar.dart';
import 'package:glow/features/receive/widgets/receive_view_switcher.dart';
import 'package:glow/features/widgets/bottom_nav_button.dart';

class ReceiveLayout extends StatelessWidget {
  final ReceiveState state;
  final ValueChanged<ReceiveMethod> onChangeMethod;
  final VoidCallback? onRequest;

  const ReceiveLayout({required this.state, required this.onChangeMethod, super.key, this.onRequest});

  @override
  Widget build(BuildContext context) {
    final bool showAppBarControls = !state.isLoading && !state.hasError;

    return Scaffold(
      appBar: ReceiveAppBar(
        showAppBarControls: showAppBarControls,
        state: state,
        onChangeMethod: onChangeMethod,
        onRequest: onRequest,
      ),
      body: ReceiveViewSwitcher(state: state),
      bottomNavigationBar: state.isLoading || state.hasError
          ? null
          : BottomNavButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              stickToBottom: true,
              text: 'CLOSE',
            ),
    );
  }
}
