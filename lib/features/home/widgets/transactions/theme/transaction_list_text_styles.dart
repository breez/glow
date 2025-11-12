import 'package:flutter/material.dart';

class TransactionListTextStyles {
  static const TextStyle emptyState = TextStyle(
    fontSize: 16.4,
    letterSpacing: 0.15,
    fontWeight: FontWeight.w500,
  );
}

class TransactionItemTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 12.25,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0.25,
  );

  static const TextStyle amount = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.28,
    letterSpacing: 0.5,
  );

  static final TextStyle fee = TextStyle(
    color: Colors.white.withValues(alpha: .7),
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    height: 1.16,
    letterSpacing: 0.39,
  );

  static final TextStyle subtitle = TextStyle(
    color: Colors.white.withValues(alpha: .7),
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    height: 1.16,
    letterSpacing: 0.39,
  );
}
