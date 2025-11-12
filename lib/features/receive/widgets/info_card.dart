import 'package:flutter/material.dart';

/// Info card widget for displaying informational messages
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoCard({required this.icon, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
