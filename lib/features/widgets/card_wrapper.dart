import 'package:flutter/material.dart';

class CardWrapper extends StatelessWidget {
  final Widget child;

  final EdgeInsetsGeometry? padding;

  const CardWrapper({required this.child, this.padding, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        color: Theme.of(context).drawerTheme.backgroundColor,
      ),
      padding: padding ?? const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: child,
    );
  }
}
