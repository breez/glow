import 'package:flutter/material.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/receive/providers/receive_form_controllers.dart';
import 'package:glow/features/receive/widgets/receive_app_bar.dart';
import 'package:glow/features/receive/widgets/receive_bottom_nav_button.dart';
import 'package:glow/features/receive/widgets/receive_view_switcher.dart';

class ReceiveLayout extends StatelessWidget {
  final ReceiveState state;
  final ValueChanged<ReceiveMethod> onChangeMethod;
  final VoidCallback onRequest;
  final VoidCallback goBackInFlow;
  final ReceiveFormControllers formControllers;
  final VoidCallback onPressed;

  const ReceiveLayout({
    required this.state,
    required this.onChangeMethod,
    required this.onRequest,
    required this.goBackInFlow,
    required this.formControllers,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReceiveAppBar(
        state: state,
        onRequest: onRequest,
        onChangeMethod: onChangeMethod,
        goBackInFlow: goBackInFlow,
      ),
      body: SafeArea(
        child: ReceiveViewSwitcher(state: state, formControllers: formControllers),
      ),
      bottomNavigationBar: ReceiveBottomNavButton(state: state, onPressed: onPressed),
    );
  }
}
