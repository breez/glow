import 'package:flutter/material.dart';

class SendForm extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String errorMessage;
  final ValueChanged<String> onSubmit;

  const SendForm({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: 'Invoice | Lightning Address | BTC Address | LNURL',
          helperText: 'Paste or scan payee information',
          errorText: errorMessage.isNotEmpty ? errorMessage : null,
        ),
        maxLines: 3,
        onFieldSubmitted: onSubmit,
      ),
    );
  }
}
