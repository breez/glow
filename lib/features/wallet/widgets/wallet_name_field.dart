import 'package:flutter/material.dart';

class WalletNameField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const WalletNameField({super.key, required this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Wallet Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.wallet),
      ),
      textCapitalization: TextCapitalization.words,
      validator: validator ?? _defaultValidator,
    );
  }

  static String? _defaultValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter a name';
    if (v.trim().length < 2) return 'At least 2 characters';
    return null;
  }
}
