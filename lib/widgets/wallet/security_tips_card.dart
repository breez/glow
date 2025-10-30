import 'package:flutter/material.dart';

class SecurityTipsCard extends StatelessWidget {
  final List<SecurityTip> tips;

  const SecurityTipsCard({super.key, this.tips = _defaultTips});

  static const _defaultTips = [
    SecurityTip(Icons.edit_note, 'Write on paper (no screenshots)'),
    SecurityTip(Icons.security, 'Store in a secure location'),
    SecurityTip(Icons.do_not_disturb, 'Never share with anyone'),
    SecurityTip(Icons.verified_user, 'Keep multiple copies'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security Tips', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12),
            ...tips.map((tip) => _SecurityTipRow(tip: tip)),
          ],
        ),
      ),
    );
  }
}

class SecurityTip {
  final IconData icon;
  final String text;

  const SecurityTip(this.icon, this.text);
}

class _SecurityTipRow extends StatelessWidget {
  final SecurityTip tip;

  const _SecurityTipRow({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(tip.icon, size: 20, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(child: Text(tip.text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
