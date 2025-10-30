import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copy text to clipboard and show a snackbar notification
void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)));
}
