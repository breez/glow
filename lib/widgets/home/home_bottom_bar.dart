import 'package:flutter/material.dart';
import 'package:glow/screens/receive/receive_screen.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'SEND',
              onPressed: null, // TODO: Implement send functionality
            ),
          ),
          Expanded(
            child: _ActionButton(label: 'RECEIVE', onPressed: () => _navigateToReceive(context)),
          ),
        ],
      ),
    );
  }

  void _navigateToReceive(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiveScreen()));
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
