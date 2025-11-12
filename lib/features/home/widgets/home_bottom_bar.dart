import 'package:flutter/material.dart';
import 'package:glow/routing/app_routes.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ActionButton(
              label: 'SEND',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.sendScreen),
            ),
          ),
          Expanded(
            child: _ActionButton(
              label: 'RECEIVE',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.receiveScreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center, maxLines: 1),
    );
  }
}
