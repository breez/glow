import 'package:flutter/material.dart';
import 'package:glow/utils/clipboard.dart';

/// Generic card widget for displaying copyable content (e.g., invoices, addresses)
class CopyableCard extends StatelessWidget {
  final String title;
  final String content;

  const CopyableCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => copyToClipboard(context, content),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Copy',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
