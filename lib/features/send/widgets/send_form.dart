import 'package:flutter/material.dart';

class SendForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String errorMessage;
  final ValueChanged<String> onSubmit;

  const SendForm({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.errorMessage,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
          prefixIcon: const SizedBox.shrink(),
          contentPadding: EdgeInsets.zero,
          hintText: 'Invoice | Lightning Address | BTC Address | LNURL',
          hintStyle: const TextStyle(fontSize: 14.3, color: Color(0x99ffffff), letterSpacing: 0.4),
          helperText: 'Paste or scan payee information',
          errorText: errorMessage.isNotEmpty ? errorMessage : null,
        ),
        style: const TextStyle(
          fontSize: 18.0,
          color: Colors.white,
          letterSpacing: 0.15,
          height: 1.234,
        ),
        validator: (String? value) => errorMessage.isNotEmpty ? errorMessage : null,
        onFieldSubmitted: onSubmit,
      ),
    );
  }
}
