import 'package:flutter/material.dart';

class WarningCard extends StatelessWidget {
  final String? title;
  final String message;
  final bool hideIcon;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;

  const WarningCard({
    required this.message,
    super.key,
    this.title,
    this.icon,
    this.iconColor,
    this.textColor,
    this.hideIcon = true,
  });
  @override
  Widget build(BuildContext context) {
    final Color warningColor = iconColor ?? Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            if (!hideIcon) ...<Widget>[
              Icon(icon ?? Icons.warning_amber_rounded, color: warningColor, size: 32),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: TextStyle(fontSize: title != null ? 14 : 13, color: textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
