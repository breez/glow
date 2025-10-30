import 'package:flutter/material.dart';

class WarningCard extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final Color? color;

  const WarningCard({super.key, this.title, required this.message, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final warningColor = color ?? Colors.orange;

    return Card(
      color: warningColor.withValues(alpha: .1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon ?? Icons.warning_amber_rounded, color: warningColor, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                  ],
                  Text(message, style: TextStyle(fontSize: title != null ? 14 : 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
