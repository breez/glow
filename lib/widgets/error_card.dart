import 'package:flutter/material.dart';
import 'package:glow/widgets/card_wrapper.dart';

class ErrorCard extends StatelessWidget {
  final String title;
  final String message;

  const ErrorCard({required this.title, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error_outline, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
