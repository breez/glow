import 'package:flutter/material.dart';

class CardWrapper extends StatelessWidget {
  final Widget child;

  final EdgeInsetsGeometry? padding;
  final Border? border;
  const CardWrapper({required this.child, this.padding, this.border, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: border ?? Border.all(color: Colors.transparent),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        color: Theme.of(context).cardTheme.color,
      ),
      padding: padding ?? const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: child,
    );
  }
}
